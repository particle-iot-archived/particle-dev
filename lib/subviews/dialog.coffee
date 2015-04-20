# Forked dialog from tree-view package: https://github.com/atom/tree-view/blob/master/lib/dialog.coffee
{$, TextEditorView, View} = require 'atom-space-pen-views'
path = require 'path'

module.exports =
class Dialog extends View
  @content: ({prompt} = {}) ->
    @div class: 'spark-dev-dialog overlay from-top', =>
      @label prompt, class: 'icon', outlet: 'promptText'
      @subview 'miniEditor', new TextEditorView(mini: true)
      @div class: 'editor-overlay', outlet: 'editorOverlay'
      @div class: 'error-message', outlet: 'errorMessage'

  initialize: ({initialText, select, iconClass, hideOnBlur} = {}) ->
    @promptText.addClass(iconClass) if iconClass
    atom.commands.add @element,
      'core:confirm': => @onConfirm(@miniEditor.getText())
      'core:cancel': => @cancel()
    @miniEditor.getModel().onDidChange => @showError()
    @miniEditor.getModel().setText(initialText)
    @miniEditor.getModel().onWillInsertText (event) =>
      if not @enabled
        event.cancel()
    @enabled = true

    if hideOnBlur
      @miniEditor.on 'blur', => @close()

    if select
      @miniEditor.getEditor().setSelectedBufferRange([[0, 0], [0, initialText.length]])

  attach: ->
    @panel = atom.workspace.addModalPanel(item: this.element)
    @miniEditor.focus()
    @miniEditor.getModel().scrollToCursorPosition()

  close: ->
    panelToDestroy = @panel
    @panel = null
    panelToDestroy?.destroy()
    atom.workspace.getActivePane().activate()

  cancel: ->
    @close()
    atom.workspace.getActivePane().activate()

  showError: (message='') ->
    @errorMessage.text(message)
    @flashError() if message

  # Show/hide loading spinner
  setLoading: (isLoading=false) ->
    @miniEditor.removeClass 'loading'
    if isLoading
      @miniEditor.addClass 'loading'

  setInputEnabled: (enabled=true) ->
    if enabled
      @editorOverlay.hide()
    else
      @editorOverlay.show()
      @miniEditor.blur()
