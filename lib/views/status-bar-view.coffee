{View} = require('atom-space-pen-views')
packageName = require '../utils/package-helper'

CompositeDisposable = null
shell = null
$ = null
spark = null

module.exports =
class StatusBarView extends View
  @content: ->
    @div =>
      @div id: 'logo-tile', class: "#{packageName()} inline-block", outlet: 'logoTile', =>
        @img src: "atom://#{packageName()}/images/logo.png"
      @div id: 'login-status-tile', class: "#{packageName()} inline-block", outlet: 'loginStatusTile'
      @div id: 'current-device-tile', class: "#{packageName()} inline-block hidden", outlet: 'currentCoreTile', =>
        @span class: 'platform-icon', outlet: 'platformIcon', title: 'Current target device', =>
          @a click: 'selectCore'
      @span id: 'compile-status-tile', class: "#{packageName()} inline-block hidden", outlet: 'compileStatusTile', =>
        @span id: 'compile-working', =>
          @span class: 'three-quarters'
          @a 'Compiling in the cloud...'
        @a id: 'compile-failed', click: 'showErrors', class:'icon icon-stop'
        @a id: 'compile-success', click: 'showFile', class:'icon icon-check'
      @span id: 'log-tile', class: "#{packageName()} inline-block", outlet: 'logTile'
      @div id: 'build-target-tile', class: "#{packageName()} inline-block", =>
        # TODO: maybe use a beaker icon for prerelease?
        @span type: 'button', class: 'icon icon-tag inline-block', outlet: 'currentBuildTargetTile', title: 'Current build target', click: 'selectBuildTarget', 'Latest'

  constructor: (@main) ->
    super

    @main.profilesDefer.promise.then =>
      @updateBuildTarget()
      @main.profileManager._onCurrentTargetPlatformChanged =>
        @updateBuildTarget()

  initialize: (serializeState) ->
    {$} = require('atom-space-pen-views')
    {CompositeDisposable} = require 'atom'

    @disposables = new CompositeDisposable
    @workspaceElement = atom.views.getView(atom.workspace)

    @getAttributesPromise = null
    @interval = null

    commands = {}
    atom.particleDev.emitter.on 'update-login-status', => @updateLoginStatus()
    commands["#{packageName()}:update-core-status"] = => @updateCoreStatus()
    commands["#{packageName()}:update-compile-status"] = => @updateCompileStatus()
    commands["#{packageName()}:update-build-target"] = => @updateBuildTarget()
    @disposables.add atom.commands.add 'atom-workspace', commands

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->

  addTiles: (statusBar) ->
    statusBar.addLeftTile(item: @logoTile, priority: 100)
    statusBar.addLeftTile(item: @loginStatusTile, priority: 110)
    statusBar.addLeftTile(item: @currentCoreTile, priority: 120)
    statusBar.addLeftTile(item: @compileStatusTile, priority: 130)
    statusBar.addLeftTile(item: @logTile, priority: 140)
    statusBar.addLeftTile(item: @currentBuildTargetTile, priority: 201)

  # Callback triggering selecting core command
  selectCore: ->
    atom.commands.dispatch @workspaceElement, "#{packageName()}:select-device"

  # Callback triggering selecting build target command
  selectBuildTarget: ->
    atom.commands.dispatch @workspaceElement, "#{packageName()}:select-build-target"

  # Callback triggering showing compile errors command
  showErrors: =>
    atom.commands.dispatch @workspaceElement, "#{packageName()}:show-compile-errors"

  # Opening file in Finder/Explorer
  showFile: ->
    shell ?= require 'shell'
    rootPath = atom.project.getPaths()[0]
    compileStatus = @main.profileManager.getLocal 'compile-status'
    shell.showItemInFolder rootPath + '/' + compileStatus.filename

  # Get current core's status from the cloud
  getCurrentCoreStatus: ->
    if !@main.profileManager.hasCurrentDevice
      return

    statusElement = @currentCoreTile.find('a')
    @currentCoreTile.removeClass 'online'

    spark = require 'spark'
    spark.login { accessToken: @main.profileManager.accessToken }
    @getAttributesPromise = spark.getAttributes @main.profileManager.currentDevice.id
    @getAttributesPromise.then (e) =>
      @main.profileManager.setLocal 'variables', {}
      @main.profileManager.setLocal 'functions', []

      if !e
        return

      # Check if current core is still available
      if e.error
        @main.profileManager.clearCurrentDevice()
        clearInterval @interval
        @interval = null
        @updateCoreStatus()
      else
        if e.connected
          @currentCoreTile.addClass 'online'

        @main.profileManager.setLocal 'current_core_name', e.name
        if !e.name
          statusElement.text 'Unnamed'
        else
          statusElement.text e.name

        @main.profileManager.setLocal 'variables', e.variables
        @main.profileManager.setLocal 'functions', e.functions

        # Periodically check if core is online
        if !@interval
          @interval = setInterval =>
            @updateCoreStatus()
          , 30000

      atom.commands.dispatch @workspaceElement, "#{packageName()}:core-status-updated"
      @getAttributesPromise = null

    , (e) =>
      console.error e

      atom.commands.dispatch @workspaceElement, "#{packageName()}:core-status-updated"
      @getAttributesPromise = null

  # Update current core's status
  updateCoreStatus: ->
    statusElement = @currentCoreTile.find('a')
    @platformIcon.removeClass()
    @platformIcon.addClass 'platform-icon'

    if @main.profileManager.hasCurrentDevice
      currentCore = @main.profileManager.currentDevice.name
      if !currentCore
        currentCore = 'Unnamed'
      statusElement.text currentCore
      @platformIcon.addClass 'platform-icon-' + @main.profileManager.currentDevice.platformId

      @getCurrentCoreStatus()
    else
      @currentCoreTile.removeClass 'online'
      statusElement.text 'No devices selected'

  # Update login status
  updateLoginStatus: ->
    @loginStatusTile.empty()

    if @main.profileManager.isLoggedIn
      username = @main.profileManager.username
      @loginStatusTile.text(username)

      @currentCoreTile.removeClass 'hidden'
      @updateCoreStatus()
    else
      loginButton = $('<a/>').text('Click to log in to Particle Cloud...')
      @loginStatusTile.append loginButton
      loginButton.on 'click', =>
        atom.commands.dispatch @workspaceElement, "#{packageName()}:login"

      @currentCoreTile.addClass 'hidden'

    atom.commands.dispatch @workspaceElement, "#{packageName()}:update-menu"

  updateCompileStatus: ->
    @compileStatusTile.addClass 'hidden'
    compileStatus = @main.profileManager.getLocal 'compile-status'

    if !!compileStatus
      @compileStatusTile.removeClass 'hidden'
      @compileStatusTile.find('>').hide()

      if !!compileStatus.working
        @compileStatusTile.find('#compile-working').show()
      else if !!compileStatus.errors
        subElement = @compileStatusTile.find('#compile-failed')
        if compileStatus.errors.length == 1
          subElement.text('One error')
        else
          subElement.text(compileStatus.errors.length + ' errors')
        subElement.show()
      else if !!compileStatus.error
        subElement = @compileStatusTile.find('#compile-failed')
        subElement.text(compileStatus.error)
        subElement.show()
      else
        @compileStatusTile.find('#compile-success')
                          .text('Success!')
                          .show()

  updateBuildTarget: ->
    @main.getBuildTargets().then (targets) =>
      currentBuildTarget = @main.getCurrentBuildTarget()
      # Clear build target if it doesn't exist for current platform
      targetExists = targets.reduce (acc, val) =>
        acc || val.version == currentBuildTarget
      , false
      currentBuildTarget = undefined if not targetExists

      if !currentBuildTarget
        latestVersion = targets.reduce (acc, val) =>
          acc || (val.version if not val.prerelease || atom.config.get("#{packageName()}.defaultToFirmwarePrereleases"))
        , undefined
        currentBuildTarget = latestVersion

      @main.setCurrentBuildTarget currentBuildTarget

      if not currentBuildTarget
        currentBuildTarget = 'Latest'
      @currentBuildTargetTile.text currentBuildTarget

  setStatus: (text, type = null) ->
    @logTile.text(text).removeClass()

    if type
      @logTile.addClass('text-' + type)

  clear: ->
    @logTile.fadeOut =>
      @setStatus ''
      @logTile.show()

  clearAfter: (delay) ->
    setTimeout =>
      @clear()
    , delay
