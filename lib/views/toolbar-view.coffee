{View} = require 'atom'
$ = null
$$ = null

module.exports =
class ToolbarView extends View
  @content: ->
    @div id: 'spark-ide-toolbar-view'

  initialize: (serializeState) ->
    {$, $$} = require 'atom'

  serialize: ->

  toggle: ->
    if @hasParent()
      @detach()
    else
      atom.workspaceView.prependToLeft @
