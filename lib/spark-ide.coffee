SettingsHelper = null
MenuManager = null

StatusView = null
LoginView = null
CoresView = null

module.exports =
  statusView: null
  loginView: null
  coresView: null

  activate: (state) ->
    # Require modules on activation
    StatusView ?= require './spark-ide-status-bar-view'
    SettingsHelper ?= require './settings-helper'
    MenuManager ?= require './menu-manager'

    # Initialize views
    statusView = new StatusView()

    # Hooking up commands
    atom.workspaceView.command 'spark-ide:login', => @login()
    atom.workspaceView.command 'spark-ide:logout', => @logout()
    atom.workspaceView.command 'spark-ide:select-core', => @selectCore()
    atom.workspaceView.command 'spark-ide:update-menu', => MenuManager.update()

    MenuManager.update()

  deactivate: ->
    @statusView?.destroy()

  serialize: ->

  login: ->
    LoginView ?= require './spark-ide-login-view'
    @loginView ?= new LoginView()
    # You may ask why this isn't in LoginView? This way, we don't need to
    # require/initialize login view until it's needed.
    atom.workspaceView.command 'spark-ide:cancel-login', => @loginView.cancelCommand()
    @loginView.show()

  logout: ->
    if !SettingsHelper.loggedIn()
      return

    LoginView ?= require './spark-ide-login-view'
    @loginView ?= new LoginView()

    @loginView.logout()

  selectCore: ->
    CoresView ?= require './spark-ide-cores-view'
    @coresView ?= new CoresView()

    if !SettingsHelper.loggedIn()
      return

    @coresView.show()
