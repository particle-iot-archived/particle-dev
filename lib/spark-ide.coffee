StatusView = null

module.exports =
  statusView: null

  activate: (state) ->
    # Require modules on activation
    StatusView ?= require './spark-ide-status-bar-view'

    # Initialize views
    statusView = new StatusView()

  deactivate: ->
    @sparkIdeView.destroy()

  serialize: ->
    null
