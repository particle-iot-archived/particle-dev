{View} = require 'atom'
$ = require('atom').$

module.exports =
class CloudVariablesAndFunctions extends View
  @content: ->
    @div id: 'spark-ide-cloud-variables-and-functions', =>
      @div id: 'spark-ide-cloud-variables', class: 'panel', =>
        @div class: 'panel-heading', 'Variables'
        @div class: 'panel-body padded'
      @div id: 'spark-ide-cloud-functions', class: 'panel', =>
        @div class: 'panel-heading', 'Functions'
        @div class: 'panel-body padded'

  initialize: (serializeState) ->
    # TODO: Hook on changing core/logging out

  serialize: ->

  destroy: ->
    @detach()

  toggle: ->
    if @hasParent()
      @detach()
    else
      atom.workspaceView.prependToBottom(this)
