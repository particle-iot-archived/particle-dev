settings = null

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
    settings ?= require './settings'

    # Initialize views
    statusView = new StatusView()

    # Hooking up commands
    atom.workspaceView.command 'spark-ide:login', => @login()
    atom.workspaceView.command 'spark-ide:logout', => @logout()
    atom.workspaceView.command 'spark-ide:select-core', => @selectCore()

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
    if !settings.access_token
      return

    LoginView ?= require './spark-ide-login-view'
    @loginView ?= new LoginView()

    @loginView.logout()

  selectCore: ->
    if !settings.access_token
      return

    CoresView ?= require './spark-ide-cores-view'
    @coresView ?= new CoresView()

    @coresView.show()
