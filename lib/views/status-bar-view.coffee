View = require('atom').View
shell = null
$ = null
SettingsHelper = null
ApiClient = null

module.exports =
class StatusBarView extends View
  @content: ->
    @div class: 'inline-block', id: 'spark-ide-status-bar-view', =>
      @img src: 'atom://spark-ide/images/spark.png', id: 'spark-icon'
      @span id: 'spark-login-status'
      @span id: 'spark-current-core', class: 'hidden', =>
        @a click: 'selectCore'
      @span id: 'spark-compile-status', class: 'hidden', =>
        @span id: 'spark-compile-working', =>
          @span class: 'three-quarters'
          @a 'Compiling in the cloud...'
        @span id: 'spark-flash-working', =>
          @span class: 'three-quarters'
          @a 'Flashing via the cloud...'
        @a id: 'spark-compile-failed', click: 'showErrors', class:'icon icon-stop'
        @a id: 'spark-compile-success', click: 'showFile', class:'icon icon-check'
      @span id: 'spark-log'

  initialize: (serializeState) ->
    $ = require('atom').$

    SettingsHelper = require '../utils/settings-helper'

    @getAttributesPromise = null
    @interval = null
    if atom.workspaceView.statusBar
      @attach()
    else
      @subscribe atom.packages.once 'activated', @attach

    atom.workspaceView.command 'spark-ide:update-login-status', => @updateLoginStatus()
    atom.workspaceView.command 'spark-ide:update-core-status', => @updateCoreStatus()
    atom.workspaceView.command 'spark-ide:update-compile-status', => @updateCompileStatus()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  attach: =>
    atom.workspaceView.statusBar.appendLeft(this)
    @updateLoginStatus()

  # Tear down any state and detach
  destroy: ->
    @remove()

  selectCore: ->
    atom.workspaceView.trigger 'spark-ide:select-core'

  showErrors: =>
    atom.workspaceView.trigger 'spark-ide:show-compile-errors'

  showFile: =>
    # Opening file in Finder/Explorer
    shell ?= require 'shell'
    rootPath = atom.project.getPath()
    compileStatus = SettingsHelper.get 'compile-status'
    shell.showItemInFolder rootPath + '/' + compileStatus.filename

  getCurrentCoreStatus: ->
    if !SettingsHelper.hasCurrentCore()
      return

    statusElement = this.find('#spark-current-core a')
    statusElement.parent().removeClass 'online'

    ApiClient = require '../vendor/ApiClient'
    client = new ApiClient SettingsHelper.get('apiUrl'), SettingsHelper.get('access_token')
    @getAttributesPromise = client.getAttributes SettingsHelper.get('current_core')
    @getAttributesPromise.done (e) =>
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

        SettingsHelper.set 'current_core_name', e.name
        statusElement.text e.name

        SettingsHelper.set 'variables', e.variables
        SettingsHelper.set 'functions', e.functions

        # Periodically check if core is online
        if !@interval
          @interval = setInterval =>
            @updateCoreStatus()
          , 30000
      @getAttributesPromise = null

  updateCoreStatus: ->
    statusElement = this.find('#spark-current-core a')

    if SettingsHelper.hasCurrentCore()
      statusElement.text SettingsHelper.get('current_core_name')

      @getCurrentCoreStatus()
    else
      statusElement.parent().removeClass 'online'
      statusElement.text 'No cores selected'

  updateLoginStatus: ->
    statusElement = this.find('#spark-login-status')
    statusElement.empty()

    ideMenu = atom.menu.template.filter (value) ->
      value.label == 'Spark IDE'

    if SettingsHelper.isLoggedIn()
      username = SettingsHelper.get('username')
      statusElement.text(username)

      this.find('#spark-current-core').removeClass 'hidden'
      @updateCoreStatus()
    else
      loginButton = $('<a/>').text('Click to log in to Spark Cloud...')
      statusElement.append loginButton
      loginButton.on 'click', =>
        atom.workspaceView.trigger 'spark-ide:login'

      this.find('#spark-current-core').addClass 'hidden'

    atom.workspaceView.trigger 'spark-ide:update-menu'

  updateCompileStatus: ->
    statusElement = this.find('#spark-compile-status')
    statusElement.addClass 'hidden'
    compileStatus = SettingsHelper.get 'compile-status'

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
      else if !!compileStatus.flashing
        statusElement.find('#spark-flash-working').show()
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
