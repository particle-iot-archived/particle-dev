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

  deactivate: ->
    @statusView?.destroy()

  serialize: ->

  login: ->
    LoginView ?= require './spark-ide-login-view'
    @loginView ?= new LoginView()
    @loginView.show()

  logout: ->
    # TODO
