React = require 'react'
LoadingIndicator = require '../components/loading-indicator'
getSubjectLocation = require '../lib/get-subject-location'
VideoPlayer = require './video-player'
PanZoom = require('./pan-zoom').default

SUBJECT_STYLE = display: 'block'
NOOP = Function.prototype

module.exports = React.createClass
  displayName: 'FrameViewer'

  getDefaultProps: ->
    subject: null
    frame: 0
    onLoad: NOOP
    classification: null
    workflow: null
    frameWrapper: null
    onChange: ->

  getInitialState: ->
    loading: true
    frameDimensions: {
      width: 0,
      height: 0
    }

  render: () ->
    subject = @props.subject
    frame = @props.frame
    {type, format, src} = getSubjectLocation @props.subject, @props.frame
    FrameWrapper = @props.frameWrapper
    frameDisplay = switch type
      when 'image'
        <div className="subject-image-frame" >
          <img ref="subjectImage" className="subject pan-active" src={src} style={SUBJECT_STYLE} onLoad={@handleLoad} tabIndex={0} onFocus={@refs.panZoom?.togglePanOn} onBlur={@refs.panZoom?.togglePanOff}/>

          {if @state.loading
            <div className="loading-cover" style={@constructor.overlayStyle} >
              <LoadingIndicator />
            </div>}
        </div>
      when 'video'
        <VideoPlayer src={src} type={type} format={format} frame={@props.frame} onLoad={@handleLoad}>
        {if @state.loading
          <div className="loading-cover" style={@constructor.overlayStyle}>
            <LoadingIndicator />
          </div>}
        </VideoPlayer>
    
    wrappedDisplay =
      <FrameWrapper 
        frame={frame} 
        naturalWidth={@state.frameDimensions?.width or 0} 
        naturalHeight={@state.frameDimensions?.height or 0} 
        viewBoxDimensions={@state.viewBoxDimensions or "0 0 0 0"} 
        workflow={@props.workflow} 
        subject={@props.subject} 
        classification={@props.classification} 
        annotation={@props.annotation} 
        loading={@state.loading}
        preferences={@props.preferences}
        modification={@props?.modification} 
        onChange={@props.onChange} 
        >
        {frameDisplay}
      </FrameWrapper>

    if FrameWrapper
      if ( @props.project? && 'pan and zoom' in @props.project?.experimental_tools)
        <PanZoom ref="panZoom" frameDimensions={@state.frameDimensions}>
          {wrappedDisplay}
        </PanZoom>
      else
        wrappedDisplay

  handleLoad: (e) ->
    width = e.target.videoWidth ? e.target.naturalWidth
    height = e.target.videoHeight ? e.target.naturalHeight
    @setState
      loading: false
      frameDimensions:
        width: width ? 0
        height: height ? 0

      viewBoxDimensions:
        width: width ? 0
        height: height ? 0
        x: 0
        y: 0

    @props.onLoad? e, @props.frame

