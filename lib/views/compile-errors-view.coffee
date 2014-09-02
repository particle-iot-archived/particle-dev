SelectListView = require('atom').SelectListView

$ = null
$$ = null
Subscriber = null
SerialHelper = null
fs = null

module.exports =
class CompileErrorsView extends SelectListView
  initialize: ->
    super

    {$, $$} = require 'atom'
    {Subscriber} = require 'emissary'

    @subscriber = new Subscriber()
    @subscriber.subscribeToCommand atom.workspaceView, 'core:cancel core:close', => @hide()

    @addClass 'overlay from-top'
    @prop 'id', 'spark-ide-compile-errors-view'


  destroy: ->
    @remove()

  show: =>
    if !@hasParent()
      atom.workspaceView.append(this)

      compileStatus = JSON.parse localStorage.getItem('compile-status')
      if compileStatus?.errors
        @setItems compileStatus.errors
      else
        @setLoading 'There were no compile errors'
      @focusFilterEditor()

  hide: ->
    if @hasParent()
      @detach()

  viewForItem: (item) ->
    $$ ->
      @li class: 'two-lines', =>
        @div class: 'primary-line', item.message
        @div class: 'secondary-line', item.file + ':' + item.row + ':' + item.col

  confirmed: (item) ->
    fs ?= require 'fs-plus'
    if fs.existsSync item.file
      filename = item.file
    else
      filename = item.file.replace '.cpp', '.ino'

    opening = atom.workspaceView.open filename, { searchAllPanes: true }
    opening.done (editor) =>
      editor.setCursorBufferPosition [item.row-1, item.col-1],
    @cancel()

  getFilterKey: ->
    'message'
