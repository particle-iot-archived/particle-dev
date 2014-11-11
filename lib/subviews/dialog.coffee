# Forked dialog from tree-view package: https://github.com/atom/tree-view/blob/master/lib/dialog.coffee
{$, TextEditorView, View} = require 'atom'
path = require 'path'

module.exports =
class Dialog extends View
  @content: ({prompt} = {}) ->
    @div class: 'spark-dev-dialog overlay from-top', =>
      @label prompt, class: 'icon', outlet: 'promptText'
      @subview 'miniEditor', new TextEditorView(mini: true)
      @div class: 'error-message', outlet: 'errorMessage'

  initialize: ({initialText, select, iconClass, hideOnBlur} = {}) ->
    @promptText.addClass(iconClass) if iconClass
    @on 'core:confirm', => @onConfirm(@miniEditor.getText())
    @on 'core:cancel', => @cancel()

    @miniEditor.getEditor().getBuffer().onDidChange => @showError()

    @miniEditor.setText(initialText)

    if hideOnBlur
      @miniEditor.hiddenInput.on 'focusout', => @remove()

    if select
      @miniEditor.getEditor().setSelectedBufferRange([[0, 0], [0, initialText.length]])

  attach: ->
    @hideOthers()
    atom.workspaceView.append(this)
    @miniEditor.focus()
    @miniEditor.getModel().scrollToCursorPosition()

  # Close other dialogs
  hideOthers: ->
    $('.spark-dev-dialog').each (idx, item) ->
      $(item).data('view').close()

  close: ->
    @remove()
    atom.workspaceView.focus()

  cancel: ->
    @remove()

  showError: (message='') ->
    @errorMessage.text(message)
    @flashError() if message

  # Show/hide loading spinner
  setLoading: (isLoading=false) ->
    @miniEditor.removeClass 'loading'
    if isLoading
      @miniEditor.addClass 'loading'
