fs = require 'fs'
path = require 'path'
gulp = require 'gulp'
cache = require 'gulp-cached'
filelog = require 'gulp-filelog'

files =
  # NOTE: The underscores here only exist so that the glob starts at the right place.
  # This keeps the output paths the way they should be.
  html: './html/**/*.ect'
  components: ['./{bower_components,_}/**/*.{html,js,css}', './{components,_}/**/*.html']
  js: ['./{js,_}/main.coffee']
  css:
    main: './{css,_}/main.styl'
    all: './{css,_}/**/*.styl'

# Get a list of all requireable files.
translations = fs.readdirSync './translations'
  .filter (file) ->
    path.extname(file) of require.extensions

# Fall back to these if a string is missing.
defaultStrings = require './translations/en-us'

buildDir = './build'

# TODO: Break this out into its own module?
transform = do ->
  eventStream = require 'event-stream'
  path = require 'path'

  ([options]..., transformation) ->
    eventStream.map (file, callback) ->
      fileExt = path.extname file.path
      if fileExt is options?.from or not options?.from?
        if options?.to?
          file.path = file.path.slice(0, file.path.lastIndexOf fileExt) + options.to

        transformation file, (error, result) ->
          # TODO: Gulp has a nice util for logging.
          console.log error.toString() if error?

          file.contents = new Buffer error?.toString() ? result

          callback error, file

      else
        # Extension didn't match.
        callback null, file

# TODO: Another module
manipulateTags = do ->
  eventStream = require 'event-stream'
  cheerio = require 'cheerio'

  (selectors) ->
    eventStream.map (file, callback) ->
      $ = cheerio.load file.contents.toString()
      tagsToGo = 0
      for selector, manipulation of selectors
        $(selector).each (tag) ->
          tagsToGo += 1
          manipulation $(this), (error) ->
            tagsToGo -= 1
            if tagsToGo is 0
              file.contents = new Buffer $.html()
              callback null, file

gulp.task 'html', ->
  ect = require 'gulp-ect'
  cheerio = require 'cheerio'
  CoffeeScript = require 'coffee-script'
  stylus = require 'stylus'
  nib = require 'nib'
  htmlFileToDirectory = require 'gulp-html-file-to-directory'
  merge = require 'lodash.merge'

  translations.forEach (translation, i) ->
    strings = require "./translations/#{translation}"

    data =
      require: require # Make local require available in templates.
      relate: (absolute) -> absolute # TODO!
      t: merge {}, defaultStrings, strings

    unless strings is defaultStrings
      translationName = translation.slice 0, translation.lastIndexOf '.'
      localBuildDir = path.join buildDir, translationName

    gulp.src files.html
      .pipe ect({data}).on 'error', console.error
      .pipe manipulateTags
        'script[type="text/coffeescript"]': (tag, callback) ->
          tag.attr 'type', null
          tag.html try
            CoffeeScript.compile tag.html()
          catch e
            e.toString()
          callback null
        'style[type="text/stylus"]': (tag, callback) ->
          tag.attr 'type', null
          stylus tag.html()
            .use nib()
            .import 'nib'
            .render (error, content) ->
              tag.html content
              callback error
      .pipe htmlFileToDirectory()
      .pipe gulp.dest localBuildDir ? buildDir
      .pipe filelog()
  return

gulp.task 'components', ->
  gulp.src files.components
    .pipe gulp.dest buildDir
    .pipe filelog()
  return

gulp.task 'js', ->
  browserify = require 'browserify'
  coffeeify = require 'coffeeify'

  gulp.src files.js
    .pipe cache 'js', optimizeMemory: true
    .pipe transform ext: 'js', squelch: true, (file, callback) ->
      b = browserify file.path, extensions: ['.coffee']
      b.transform coffeeify
      b.bundle callback
    .pipe gulp.dest buildDir
    .pipe filelog()
  return

gulp.task 'css', ->
  stylus = require 'stylus'
  nib = require 'nib'

  gulp.src files.css.main
    .pipe transform ext: 'css', squelch: true, (file, callback) ->
      stylus file.contents.toString(), filename: file.path
        .use nib()
        .import 'nib'
        .render callback
    .pipe gulp.dest buildDir
    .pipe filelog()
  return

gulp.task 'build', ['html', 'components', 'js', 'css']

gulp.task 'watch', ['build'], ->
  gulp.watch ['./translations/**/*'].concat(files.html), ['html']
  gulp.watch files.components, ['components']
  gulp.watch files.js, ['js']
  gulp.watch files.css.all, ['css']
  return

gulp.task 'serve', (next) ->
  connect = require 'connect'
  livereload = require 'gulp-livereload'

  port = process.env.PORT || 3735

  staticServer = connect()
  staticServer.use connect.static buildDir
  staticServer.listen port, next
  console.log "Static server listening on: #{port}"

  changeServer = livereload()
  gulp.watch "#{buildDir}/**/*"
    .on 'change', (file) ->
      changeServer.changed file.path
  return

gulp.task 'default', ['watch', 'serve']
