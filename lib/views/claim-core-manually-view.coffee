Dialog = require '../vendor/dialog'
SettingsHelper = null
_s = null

module.exports =
class ClaimCoreManuallyView extends Dialog
  constructor: ->
    super
      prompt: 'Enter device ID (hex string)'
      initialText: ''
      select: false
      iconClass: ''
      hideOnBlur: false

    @claimPromise = null
    @prop 'id', 'spark-ide-claim-core-manually-view'

  onConfirm: (deviceID) ->

    SettingsHelper ?= require '../utils/settings-helper'
    _s ?= require 'underscore.string'

    @miniEditor.removeClass 'editor-error'
    deviceID = _s.trim(deviceID)
    if deviceID == ''
      @miniEditor.addClass 'editor-error'
    else
      @miniEditor.hiddenInput.attr 'disabled', 'disabled'

      ApiClient = require '../vendor/ApiClient'
      client = new ApiClient SettingsHelper.get('apiUrl'), SettingsHelper.get('access_token')
      workspace = atom.workspaceView
      @claimPromise = client.claimCore deviceID
      @setLoading true
      @claimPromise.done (e) =>
        if !@claimPromise
          return

        SettingsHelper.setCurrentCore e.id, e.id

        atom.workspaceView.trigger 'spark-ide:update-core-status'
        atom.workspaceView.trigger 'spark-ide:update-menu'

        @claimPromise = null
        @close()

      , (e) =>
        @setLoading false
        @miniEditor.addClass 'editor-error'
        @showError(e.errors)
        @claimPromise = null
