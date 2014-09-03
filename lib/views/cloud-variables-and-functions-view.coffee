{View} = require 'atom'
$ = require('atom').$
$$ = require('atom').$$

module.exports =
class CloudVariablesAndFunctions extends View
  @content: ->
    @div id: 'spark-ide-cloud-variables-and-functions', =>
      @div id: 'spark-ide-cloud-variables', class: 'panel', =>
        @div class: 'panel-heading', 'Variables'
        @div class: 'panel-body padded', outlet: 'variables'
      @div id: 'spark-ide-cloud-functions', class: 'panel', =>
        @div class: 'panel-heading', 'Functions'
        @div class: 'panel-body padded', outlet: 'functions'

  initialize: (serializeState) ->
    # TODO: Hook on changing core/logging out
    @variables.append $$ ->
      @ul class: 'background-message', =>
        @li 'No variables registered'

    @functions.append $$ ->
      @ul class: 'background-message', =>
        @li 'No functions registered'

  serialize: ->

  destroy: ->
    @detach()

  toggle: ->
    if @hasParent()
      @detach()
    else
      atom.workspaceView.prependToBottom(this)
