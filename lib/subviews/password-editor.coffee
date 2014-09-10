{EditorView} = require 'atom'

module.exports =
class PasswordView extends EditorView
  constructor: (editorOrParams, props) ->
    editorOrParams.mini = true
    super editorOrParams, props
