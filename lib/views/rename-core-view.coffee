Dialog = require '../subviews/dialog'
SettingsHelper = null
_s = null

module.exports =
class RenameCoreView extends Dialog
  constructor: (@initialName) ->
    super
      prompt: 'Enter new name for this Core'
      initialText: @initialName
      select: true
      iconClass: ''
      hideOnBlur: false

    @renamePromise = null
    @prop 'id', 'spark-ide-rename-core-view'

  onConfirm: (newName) ->
    SettingsHelper ?= require '../utils/settings-helper'
    _s ?= require 'underscore.string'

    @miniEditor.removeClass 'editor-error'
    newName = _s.trim(newName)
    if newName == ''
      @miniEditor.addClass 'editor-error'
    else
      @miniEditor.hiddenInput.attr 'disabled', 'disabled'

      ApiClient = require '../vendor/ApiClient'
      client = new ApiClient SettingsHelper.get('apiUrl'), SettingsHelper.get('access_token')
      workspace = atom.workspaceView
      @renamePromise = client.renameCore SettingsHelper.get('current_core'), newName
      @setLoading true
      @renamePromise.done (e) =>
        if !@renamePromise
          return

        atom.workspaceView = workspace
        SettingsHelper.set 'current_core_name', newName
        atom.workspaceView.trigger 'spark-ide:update-core-status'
        atom.workspaceView.trigger 'spark-ide:update-menu'
        @renamePromise = null

        @close()

      , (e) =>
        @setLoading false
        @renamePromise = null
        @miniEditor.hiddenInput.removeAttr 'disabled'
        atom.confirm
          message: 'Error'
          detailedMessage: e
