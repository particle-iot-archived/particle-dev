{$$$, EditorView, View} = require 'atom'
$ = null
_s = null

module.exports =
class SparkIdeLoginView extends View
  @content: ->
    @div class: 'spark-ide-login-view overlay from-top', =>
      @h1 'Log in to Spark Cloud'
      @subview 'emailEditor', new EditorView(mini: true, placeholderText: 'Could I please have an email address?')
      @subview 'passwordEditor', new EditorView(mini: true, placeholderText: 'and a password?'), outlet: 'passwordEditor'
      @div class: 'block', =>
        @button click: 'cancel', class: 'btn', 'Cancel'

  initialize: (serializeState) ->
    $ = require('atom').$
    _s = require 'underscore.string'

    # As Atom doesn't provide password input, we have to hack EditorView to act as one
    #
    # Known issues:
    # * doesn't support pasting (it will show plain text)
    # * doesn't work with multiple selections
    @passwordEditor.originalText = ''
    @passwordEditor.hiddenInput.on 'keypress', (e) =>
      editor = @passwordEditor.getEditor()
      selection = editor.getSelectedBufferRange()
      cursor = editor.getCursorBufferPosition()
      if !selection.isEmpty()
        @passwordEditor.originalText = _s.splice(@passwordEditor.originalText, selection.start.column, selection.end.column - selection.start.column, String.fromCharCode(e.which))
      else
        @passwordEditor.originalText = _s.splice(@passwordEditor.originalText, cursor.column, 0, String.fromCharCode(e.which))
      @passwordEditor.insertText '*'
      false

    @passwordEditor.hiddenInput.on 'keydown', (e) =>
      console.log 'keydown ', e.which
      if e.which == 8
        editor = @passwordEditor.getEditor()
        selection = editor.getSelectedBufferRange()
        cursor = editor.getCursorBufferPosition()
        if !selection.isEmpty()
          @passwordEditor.originalText = _s.splice(@passwordEditor.originalText, selection.start.column, selection.end.column - selection.start.column)
        else
          @passwordEditor.originalText = _s.splice(@passwordEditor.originalText, cursor.column - 1, 1)
        @passwordEditor.backspace
        false
      true

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @remove()

  show: ->
    if !@hasParent()
      atom.workspaceView.append(this)

  hide: ->
    if @hasParent()
      @detach()

  cancel: (event, element) ->
    @hide()
