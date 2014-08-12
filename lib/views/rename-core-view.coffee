Dialog = require(atom.packages.getLoadedPackage('tree-view')?.path + '/lib/dialog')
SettingsHelper = null
_s = null

module.exports =
class RenameCoreView extends Dialog
  constructor: (@initialName) ->
    super
      prompt: 'Enter new name for this Core'
      initialPath: @initialName
      select: true
      iconClass: ''

    @renamePromise = null

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

      @renamePromise = client.renameCore SettingsHelper.get('current_core'), newName
      @renamePromise.done (e) =>
        if !@renamePromise
          return
        SettingsHelper.set 'current_core_name', newName
        atom.workspaceView.trigger 'spark-ide:update-core-status'
        @renamePromise = null

        @close()

      , (e) =>
        @miniEditor.hiddenInput.removeAttr 'disabled'
        atom.confirm
          message: 'Error'
          detailedMessage: e
