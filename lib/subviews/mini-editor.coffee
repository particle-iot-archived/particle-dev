{$, View, TextEditorView} = require 'atom-space-pen-views'

module.exports =
class MiniEditor extends View
	@content: ->
		@div class: 'spark-dev-mini-editor', =>
			@subview 'editor', new TextEditorView(mini: true)
			@div class: 'editor-disabled', outlet: 'editorOverlay'

	initialize: ->
		@enabled = true
		@editor.on 'focus', =>
			if not @enabled
				@editor.blur()

	setEnabled: (isEnabled) ->
		@enabled = isEnabled
		if isEnabled
			@editorOverlay.hide()
		else
			@editorOverlay.show()
			@editor.blur()

	# Show/hide loading spinner
	setLoading: (isLoading=false) ->
		@removeClass 'loading'
		if isLoading
			@addClass 'loading'
