{Dialog} = require 'spark-dev-views'
SettingsHelper = null
_s = null

module.exports =
class ClaimCoreView extends Dialog
  constructor: ->
    super
      prompt: 'Enter device ID (hex string)'
      initialText: ''
      select: false
      iconClass: ''
      hideOnBlur: false

    @claimPromise = null
    @prop 'id', 'spark-dev-claim-core-view'
    @workspaceElement = atom.views.getView(atom.workspace)

  # When deviceID is submited
  onConfirm: (deviceID) ->
    SettingsHelper ?= require '../utils/settings-helper'
    _s ?= require 'underscore.string'

    # Remove any errors
    @miniEditor.editor.removeClass 'editor-error'
    # Trim deviceID from any whitespaces
    deviceID = _s.trim(deviceID)

    if deviceID == ''
      # Empty deviceID is not allowed
      @miniEditor.editor.addClass 'editor-error'
    else
      # Lock input
      @miniEditor.setEnabled false
      @miniEditor.setLoading true

      spark = require 'spark'
      spark.login { accessToken: SettingsHelper.get('access_token') }

      # Claim core via API
      @claimPromise = spark.claimCore deviceID
      @setLoading true
      @claimPromise.done (e) =>
        @miniEditor.setLoading false
        if e.ok
          if !@claimPromise
            return

          # Set current core in settings
          SettingsHelper.setCurrentCore e.id, null

          # Refresh UI
          atom.commands.dispatch @workspaceElement, 'spark-dev:update-core-status'
          atom.commands.dispatch @workspaceElement, 'spark-dev:update-menu'

          @claimPromise = null
          @close()
        else
          @miniEditor.setEnabled true
          @miniEditor.editor.addClass 'editor-error'
          @showError e.errors

          @claimPromise = null

      , (e) =>
        @setLoading false
        # Show error
        @miniEditor.setEnabled true

        if e.code == 'ENOTFOUND'
          message = 'Error while connecting to ' + e.hostname
          @showError message
        else
          @miniEditor.editor.addClass 'editor-error'
          @showError e.errors

        @claimPromise = null
