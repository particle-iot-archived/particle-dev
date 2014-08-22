View = require('atom').View
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

  getCurrentCoreStatus: ->
    if !SettingsHelper.hasCurrentCore()
      return

    statusElement = this.find('#spark-current-core a')
    statusElement.parent().removeClass 'online'

    ApiClient = require '../vendor/ApiClient'
    client = new ApiClient SettingsHelper.get('apiUrl'), SettingsHelper.get('access_token')
    @getAttributesPromise = client.getAttributes SettingsHelper.get('current_core')
    @getAttributesPromise.done (e) =>
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

  setStatus: (text, type = null) ->
      el = this.find('#spark-log')
      console.log el
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
