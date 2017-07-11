{DialogView} = require 'particle-dev-views'
packageName = require '../utils/package-helper'
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
    @main = null
    @prop 'id', 'rename-core-view'
    @addClass packageName()
    @workspaceElement = atom.views.getView(atom.workspace)

  onConfirm: (newName) ->
    _s ?= require 'underscore.string'

    @miniEditor.editor.removeClass 'editor-error'
    newName = _s.trim(newName)
    if newName == ''
      @miniEditor.editor.addClass 'editor-error'
    else
      spark ?= require 'spark'
      spark.login { accessToken: @main.profileManager.accessToken }
      @renamePromise = spark.renameCore @main.profileManager.currentDevice.id, newName
      @miniEditor.setLoading true
      @miniEditor.setEnabled false

      @renamePromise.then (e) =>
        @miniEditor.setLoading false
        if !@renamePromise
          return

        currentDevice = @main.profileManager.currentDevice
        currentDevice.name = newName
        @main.profileManager.currentDevice = currentDevice

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
