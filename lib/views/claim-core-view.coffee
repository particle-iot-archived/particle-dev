Dialog = require '../subviews/dialog'
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
    @prop 'id', 'spark-ide-claim-core-view'

  # When deviceID is submited
  onConfirm: (deviceID) ->
    SettingsHelper ?= require '../utils/settings-helper'
    _s ?= require 'underscore.string'

    # Remove any errors
    @miniEditor.removeClass 'editor-error'
    # Trim deviceID from any whitespaces
    deviceID = _s.trim(deviceID)

    if deviceID == ''
      # Empty deviceID is not allowed
      @miniEditor.addClass 'editor-error'
    else
      # Unlock input
      @miniEditor.hiddenInput.attr 'disabled', 'disabled'

      ApiClient = require '../vendor/ApiClient'
      client = new ApiClient SettingsHelper.get('apiUrl'), SettingsHelper.get('access_token')
      workspace = atom.workspaceView
      # Claim core via API
      @claimPromise = client.claimCore deviceID
      @setLoading true
      @claimPromise.done (e) =>
        if !@claimPromise
          return

        # Set current core in settings
        SettingsHelper.setCurrentCore e.id, e.id

        # Refresh UI
        atom.workspaceView.trigger 'spark-ide:update-core-status'
        atom.workspaceView.trigger 'spark-ide:update-menu'

        @claimPromise = null
        @close()

      , (e) =>
        @setLoading false
        # Show error
        @miniEditor.addClass 'editor-error'
        @showError(e.errors)
        @claimPromise = null
