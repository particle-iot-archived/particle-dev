SelectListView = require('atom').SelectListView

$ = null
$$ = null
Subscriber = null
SerialHelper = null
SettingsHelper = null
fs = null
path = null

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

  @parseErrors: (raw) ->
    path ?= require 'path'

    lines = raw.split "\n"
    errors = []
    for line in lines
      result = line.match /^([^:]+):(\d+):(\d+):\s(\w+):(.*)$/
      if result and result[4] == 'error'
        errors.push {
          file: result[1],
          row: result[2],
          col: result[3],
          type: result[4],
          message: result[5]
        }
      else
        result = line.match /^([^:]+):(\d+):\s(.*)$/
        if result
          # This is probably "undefined" error
          errors.push {
            file: path.basename(result[1]),
            row: result[2],
            col: 0,
            type: 'error',
            message: result[3]
          }
    errors

  destroy: ->
    @remove()

  show: =>
    if !@hasParent()
      SettingsHelper ?= require '../utils/settings-helper'

      atom.workspaceView.append(this)

      compileStatus = SettingsHelper.get 'compile-status'
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
