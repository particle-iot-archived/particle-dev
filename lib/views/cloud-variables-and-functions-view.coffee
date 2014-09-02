{View} = require 'atom'
$ = require('atom').$

module.exports =
class CloudVariablesAndFunctions extends View
  @content: ->
      @div 'Foo'

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
