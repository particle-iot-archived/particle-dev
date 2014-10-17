{TextEditorView} = require 'atom'

module.exports =
class PasswordView extends TextEditorView
  constructor: (editorOrParams, props) ->
    editorOrParams.mini = true
    super editorOrParams, props

    # TODO: support pasting (now it will show plain text)
    # TODO: work with multiple selections

    @hiddenInput.on 'keypress', (e) =>
      editor = @getEditor()
      selection = editor.getSelectedBufferRange()
      cursor = editor.getCursorBufferPosition()
      if !selection.isEmpty()
        @originalText = _s.splice(@originalText, selection.start.column, selection.end.column - selection.start.column, String.fromCharCode(e.which))
      else
        @originalText = _s.splice(@originalText, cursor.column, 0, String.fromCharCode(e.which))
      @insertText '*'
      false

    @hiddenInput.on 'keydown', (e) =>
      if e.which == 8
        editor = @getEditor()
        selection = editor.getSelectedBufferRange()
        cursor = editor.getCursorBufferPosition()
        if !selection.isEmpty()
          @originalText = _s.splice(@originalText, selection.start.column, selection.end.column - selection.start.column)
        else
          @originalText = _s.splice(@originalText, cursor.column - 1, 1)
        @backspace
      else if e.which == 13
        @trigger 'core:confirm'
      true
