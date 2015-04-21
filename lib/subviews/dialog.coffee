# Forked dialog from tree-view package: https://github.com/atom/tree-view/blob/master/lib/dialog.coffee
{$, View} = require 'atom-space-pen-views'
path = require 'path'
MiniEditor = require './mini-editor'

module.exports =
class Dialog extends View
  @content: ({prompt} = {}) ->
    @div class: 'spark-dev-dialog overlay from-top', =>
      @label prompt, class: 'icon', outlet: 'promptText'
      @subview 'miniEditor', new MiniEditor()
      @div class: 'error-message', outlet: 'errorMessage'

  initialize: ({initialText, select, iconClass, hideOnBlur} = {}) ->
    @promptText.addClass(iconClass) if iconClass
    @model = @miniEditor.editor.getModel()
    atom.commands.add @element,
      'core:confirm': => @onConfirm(@model.getText())
      'core:cancel': => @cancel()
    @model.onDidChange => @showError()
    @model.setText(initialText)
    @model.onWillInsertText (event) =>
      if not @enabled
        event.cancel()
    @enabled = true

    if hideOnBlur
      @miniEditor.editor.on 'blur', => @close()

    if select
      @model.setSelectedBufferRange([[0, 0], [0, initialText.length]])

  attach: ->
    @panel = atom.workspace.addModalPanel(item: this.element)
    @miniEditor.editor.focus()
    @model.scrollToCursorPosition()

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
  setLoading: (isLoading) ->
    @miniEditor.setLoading isLoading
