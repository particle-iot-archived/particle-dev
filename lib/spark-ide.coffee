StatusView = null

module.exports =
  statusView: null

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
    # TODO
    console.log 'Log in...'

  logout: ->
    # TODO
