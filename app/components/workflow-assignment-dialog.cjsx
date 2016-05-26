React = require 'react'
Dialog = require 'modal-form/dialog'

module.exports = React.createClass
  displayName: 'WorkflowAssignmentDialog'

  statics:
    start: (history, location, preferences) ->
      WorkflowAssignmentDialog = this
      Dialog.alert(<WorkflowAssignmentDialog />, {
        className: 'workflow-assignment-dialog', 
        closeButton: true,
        onCancel: @handleStayOnCurrentWorkflowAssignment.bind(null, location, preferences),
        onSubmit: @handleNewWorklfowAssignment.bind(null, history, location, preferences)
      })

    handleNewWorklfowAssignment: (history, location, preferences) ->
      history.replace pathname: location.pathname, search: "?workflow=#{preferences.preferences.selected_workflow}"

    handleStayOnCurrentWorkflowAssignment: (location, preferences) ->
      # Switch user back to workflow in query rather than nero assigned workflow
      # TODO: Maybe if user selects after 3 prompts, opt out?
      preferences.update "preferences.selected_workflow": location.query.workflow
      preferences.save()

  render: ->
    <div className="content-container">
      <p>You've done a great job classifying. We'd like to recommend a more advanced task workflow for you to try out.</p>
      <p>You now have a setting in your profile if you change your mind want to change which workflow you are on later.</p>
      <button type="submit">Try the new workflow</button>
    </div>


