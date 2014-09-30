{View, EditorView} = require 'atom'
{Emitter} = require 'event-kit'
$ = null
$$ = null
whenjs = require 'when'
SettingsHelper = null

module.exports =
class SerialMonitorView extends View
  @content: ->
    @div id: 'spark-ide-serial-monitor', =>
      @pre outlet: 'output'
      @subview 'input', new EditorView(mini: true)

  initialize: (serializeState) ->
    {$, $$} = require 'atom'
    SettingsHelper = require '../utils/settings-helper'

    @emitter = new Emitter

  serialize: ->

  getTitle: ->
    'Serial monitor'

  onDidChangeTitle: (callback) ->
    @emitter.on 'did-change-title', callback

  onDidChangeModified: (callback) ->
    @emitter.on 'did-change-modified', callback

  getUri: ->
    'spark-ide://editor/serial-monitor'

  close: ->
    pane = atom.workspace.paneForUri @getUri()
    pane.destroy()
