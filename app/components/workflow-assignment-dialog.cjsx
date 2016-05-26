React = require 'react'
Dialog = require 'modal-form/dialog'
apiClient = require 'panoptes-client/lib/api-client'

module.exports = React.createClass
  displayName: 'WorkflowAssignmentDialog'

  getDefaultProps: ->
    onCancelWorkflowAssignment: ->
    currentWorkflow: ''
    nextWorkflow: ''

  render: ->
    console.log('rendering')
    <div className="content-container">
      <p>You've done a great job classifying. We'd like to recommend a more advanced task workflow for you to try out.</p>
      <p>You now have a setting in your profile if you change your mind want to change which workflow you are on later.</p>
      <button type="submit">Try the new workflow</button>
      <button type="button" onClick={@props.onCancelWorkflowAssignment}>Stay on the current workflow</button>
    </div>


