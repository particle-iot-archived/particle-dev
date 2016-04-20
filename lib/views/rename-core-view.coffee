{DialogView} = require 'particle-dev-views'
packageName = require '../utils/package-helper'
SettingsHelper = null
_s = null
spark = null

module.exports =
class RenameCoreView extends DialogView
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
    @prop 'id', "#{packageName()}-rename-core-view"
    @workspaceElement = atom.views.getView(atom.workspace)

  onConfirm: (newName) ->
    SettingsHelper ?= require '../utils/settings-helper'
    _s ?= require 'underscore.string'

    @miniEditor.editor.removeClass 'editor-error'
    newName = _s.trim(newName)
    if newName == ''
      @miniEditor.editor.addClass 'editor-error'
    else
      spark ?= require 'spark'
      spark.login { accessToken: SettingsHelper.get('access_token') }
      @renamePromise = spark.renameCore SettingsHelper.getLocal('current_core'), newName
      @miniEditor.setLoading true
      @miniEditor.setEnabled false

      @renamePromise.then (e) =>
        @miniEditor.setLoading false
        if !@renamePromise
          return

        SettingsHelper.setLocal 'current_core_name', newName

        atom.commands.dispatch @workspaceElement, "#{packageName()}:update-core-status"
        atom.commands.dispatch @workspaceElement, "#{packageName()}:update-menu"
        @renamePromise = null

        @close()

      , (e) =>
        @miniEditor.setLoading false
        @renamePromise = null
        @miniEditor.setEnabled true
        if e.code == 'ENOTFOUND'
          message = 'Error while connecting to ' + e.hostname
        else
          message = e.message

        atom.confirm
          message: 'Error'
          detailedMessage: message
