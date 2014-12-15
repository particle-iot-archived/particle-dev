Dialog = require '../subviews/dialog'
SettingsHelper = null
_s = null
spark = null

module.exports =
class RenameCoreView extends Dialog
  constructor: (@initialName) ->
    if !@initialName
      @initialName = ''
    super
      prompt: 'Enter new name for this Core'
      initialText: @initialName
      select: true
      iconClass: ''
      hideOnBlur: false

    @renamePromise = null
    @prop 'id', 'spark-dev-rename-core-view'

  onConfirm: (newName) ->
    SettingsHelper ?= require '../utils/settings-helper'
    _s ?= require 'underscore.string'

    @miniEditor.removeClass 'editor-error'
    newName = _s.trim(newName)
    if newName == ''
      @miniEditor.addClass 'editor-error'
    else
      @miniEditor.hiddenInput.attr 'disabled', 'disabled'

      spark ?= require 'spark'
      spark.login { accessToken: SettingsHelper.get('access_token') }
      workspace = atom.workspaceView
      @renamePromise = spark.renameCore SettingsHelper.getLocal('current_core'), newName
      @setLoading true
      @renamePromise.done (e) =>
        if !@renamePromise
          return

        atom.workspaceView = workspace
        SettingsHelper.setLocal 'current_core_name', newName
        atom.workspaceView.trigger 'spark-dev:update-core-status'
        atom.workspaceView.trigger 'spark-dev:update-menu'
        @renamePromise = null

        @close()

      , (e) =>
        @setLoading false
        @renamePromise = null
        @miniEditor.hiddenInput.removeAttr 'disabled'
        if e.code == 'ENOTFOUND'
          message = 'Error while connecting to ' + e.hostname
        else
          message = e.message

        atom.confirm
          message: 'Error'
          detailedMessage: message
