StatusView = null
LoginView = null

module.exports =
  statusView: null
  loginView: null

  activate: (state) ->
    # Require modules on activation
    StatusView ?= require './spark-ide-status-bar-view'

    # Initialize views
    statusView = new StatusView()

    # Hooking up commands
    atom.workspaceView.command 'spark-ide:login', => @login()
    atom.workspaceView.command 'spark-ide:logout', => @logout()

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
    LoginView ?= require './spark-ide-login-view'
    @loginView ?= new LoginView()

    @loginView.logout()
