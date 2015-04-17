{View} = require('atom-space-pen-views')
CompositeDisposable = null
shell = null
$ = null
SettingsHelper = null
spark = null

module.exports =
class StatusBarView extends View
  @content: ->
    @div class: 'inline-block', id: 'spark-dev-status-bar-view', =>
      @img src: 'atom://spark-dev/images/spark.png', id: 'spark-icon'
      @span id: 'spark-login-status'
      @span id: 'spark-current-core', class: 'hidden', =>
        @a click: 'selectCore'
      @span id: 'spark-compile-status', class: 'hidden', =>
        @span id: 'spark-compile-working', =>
          @span class: 'three-quarters'
          @a 'Compiling in the cloud...'
        @a id: 'spark-compile-failed', click: 'showErrors', class:'icon icon-stop'
        @a id: 'spark-compile-success', click: 'showFile', class:'icon icon-check'
      @span id: 'spark-log'

  initialize: (serializeState) ->
    {$} = require('atom-space-pen-views')
    {CompositeDisposable} = require 'atom'

    @disposables = new CompositeDisposable
    @workspaceElement = atom.views.getView(atom.workspace)

    SettingsHelper = require '../utils/settings-helper'

    @getAttributesPromise = null
    @interval = null
    if @workspaceElement.statusBar
      @attach()
    else
      atom.packages.onDidActivateAll =>
        @attach()

    @disposables.add atom.commands.add 'atom-workspace',
      'spark-dev:update-login-status': => @updateLoginStatus()
      'spark-dev:update-core-status': => @updateCoreStatus()
      'spark-dev:update-compile-status': => @updateCompileStatus()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  attach: =>
    @workspaceElement.statusBar.appendLeft(this)
    @updateLoginStatus()

  # Tear down any state and detach
  destroy: ->
    @remove()

  # Callback triggering selecting core command
  selectCore: ->
    atom.workspaceView.trigger 'spark-dev:select-device'

  # Callback triggering showing compile errors command
  showErrors: =>
    atom.workspaceView.trigger 'spark-dev:show-compile-errors'

  # Opening file in Finder/Explorer
  showFile: =>
    shell ?= require 'shell'
    rootPath = atom.project.getPaths()[0]
    compileStatus = SettingsHelper.getLocal 'compile-status'
    shell.showItemInFolder rootPath + '/' + compileStatus.filename

  # Get current core's status from the cloud
  getCurrentCoreStatus: ->
    if !SettingsHelper.hasCurrentCore()
      return

    statusElement = this.find('#spark-current-core a')
    statusElement.parent().removeClass 'online'

    spark = require 'spark'
    spark.login { accessToken: SettingsHelper.get('access_token') }
    @getAttributesPromise = spark.getAttributes SettingsHelper.getLocal('current_core')
    @getAttributesPromise.done (e) =>
      SettingsHelper.setLocal 'variables', {}
      SettingsHelper.setLocal 'functions', []

      if !e
        return

      # Check if current core is still available
      if e.error
        SettingsHelper.clearCurrentCore()
        clearInterval @interval
        @interval = null
        @updateCoreStatus()
      else
        if e.connected
          statusElement.parent().addClass 'online'

        SettingsHelper.setLocal 'current_core_name', e.name
        if !e.name
          statusElement.text 'Unnamed'
        else
          statusElement.text e.name

        SettingsHelper.setLocal 'variables', e.variables
        SettingsHelper.setLocal 'functions', e.functions

        # Periodically check if core is online
        if !@interval
          @interval = setInterval =>
            @updateCoreStatus()
          , 30000

      atom.workspaceView.trigger 'spark-dev:core-status-updated'
      @getAttributesPromise = null

    , (e) =>
      console.error e

      atom.workspaceView.trigger 'spark-dev:core-status-updated'
      @getAttributesPromise = null

  # Update current core's status
  updateCoreStatus: ->
    statusElement = this.find('#spark-current-core a')

    if SettingsHelper.hasCurrentCore()
      currentCore = SettingsHelper.getLocal('current_core_name')
      if !currentCore
        currentCore = 'Unnamed'
      statusElement.text currentCore

      @getCurrentCoreStatus()
    else
      statusElement.parent().removeClass 'online'
      statusElement.text 'No devices selected'

  # Update login status
  updateLoginStatus: ->
    statusElement = this.find('#spark-login-status')
    statusElement.empty()

    ideMenu = atom.menu.template.filter (value) ->
      value.label == 'Spark Dev'

    if SettingsHelper.isLoggedIn()
      username = SettingsHelper.get('username')
      statusElement.text(username)

      this.find('#spark-current-core').removeClass 'hidden'
      @updateCoreStatus()
    else
      loginButton = $('<a/>').text('Click to log in to Spark Cloud...')
      statusElement.append loginButton
      loginButton.on 'click', =>
        atom.workspaceView.trigger 'spark-dev:login'

      this.find('#spark-current-core').addClass 'hidden'

    atom.workspaceView.trigger 'spark-dev:update-menu'

  updateCompileStatus: ->
    statusElement = this.find('#spark-compile-status')
    statusElement.addClass 'hidden'
    compileStatus = SettingsHelper.getLocal 'compile-status'

    if !!compileStatus
      statusElement.removeClass 'hidden'
      statusElement.find('>').hide()

      if !!compileStatus.working
        statusElement.find('#spark-compile-working').show()
      else if !!compileStatus.errors
        subElement = statusElement.find('#spark-compile-failed')
        if compileStatus.errors.length == 1
          subElement.text('One error')
        else
          subElement.text(compileStatus.errors.length + ' errors')
        subElement.show()
      else if !!compileStatus.error
        subElement = statusElement.find('#spark-compile-failed')
        subElement.text(compileStatus.error)
        subElement.show()
      else
        statusElement.find('#spark-compile-success')
                     .text('Success! Firmware saved to ' + compileStatus.filename)
                     .show()

  setStatus: (text, type = null) ->
      el = this.find('#spark-log')
      el.text(text)
        .removeClass()

      if type
        el.addClass('text-' + type)

  clear: ->
    el = this.find('#spark-log')
    self = @
    el.fadeOut ->
      self.setStatus ''
      el.show()

  clearAfter: (delay) ->
    setTimeout =>
      @clear()
    , delay
