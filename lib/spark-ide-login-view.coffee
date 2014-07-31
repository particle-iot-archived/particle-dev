{$$$, EditorView, View} = require 'atom'
$ = null
_s = null
Subscriber = null
ApiClient = null
settings = null
validator = null

module.exports =
class SparkIdeLoginView extends View
  @content: ->
    @div id: 'spark-ide-login-view', class: 'overlay from-top', =>
      @div class: 'block', =>
        @span 'Log in to Spark Cloud '
        @span class: 'text-subtle', =>
          @text 'Close this dialog with the '
          @span class: 'highlight', 'esc'
          @span ' key'
      @subview 'emailEditor', new EditorView(mini: true, placeholderText: 'Could I please have an email address?'), outlet: 'emailEditor'
      @subview 'passwordEditor', new EditorView(mini: true, placeholderText: 'and a password?'), outlet: 'passwordEditor'
      @div class: 'block', =>
        @button click: 'login', class: 'btn btn-primary', outlet: 'loginButton', 'Log in'
        @button click: 'cancel', class: 'btn', outlet: 'cancelButton', 'Cancel'
        @span class: 'loading loading-spinner-tiny inline-block hidden', outlet: 'spinner'
        @a href: 'https://www.spark.io/forgot-password', class: 'pull-right', 'Forgot password?'

  initialize: (serializeState) ->
    {Subscriber} = require 'emissary'
    $ = require('atom').$
    _s = require 'underscore.string'
    settings = require './settings'

    @subscriber = new Subscriber()

    @subscriber.subscribeToCommand atom.workspaceView, 'core:cancel core:close', ({target}) =>
      @cancel()

    @loginPromise = null

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
      if e.which == 8
        editor = @passwordEditor.getEditor()
        selection = editor.getSelectedBufferRange()
        cursor = editor.getCursorBufferPosition()
        if !selection.isEmpty()
          @passwordEditor.originalText = _s.splice(@passwordEditor.originalText, selection.start.column, selection.end.column - selection.start.column)
        else
          @passwordEditor.originalText = _s.splice(@passwordEditor.originalText, cursor.column - 1, 1)
        @passwordEditor.backspace
      true

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @remove()

  show: ->
    if !@hasParent()
      atom.workspaceView.append(this)
      @emailEditor.getEditor().setText ''
      @passwordEditor.getEditor().setText ''
      @passwordEditor.originalText = ''

  hide: ->
    if @hasParent()
      @detach()

  cancel: (event, element) ->
    if !!@loginPromise
      # TODO: Cancel login
    @hide()

  validateInputs: ->
    validator ?= require 'validator'

    @emailEditor.removeClass 'editor-error'
    @passwordEditor.removeClass 'editor-error'

    @email = _s.trim(@emailEditor.getText())
    @password = _s.trim(@passwordEditor.originalText)

    isOk = true

    if (@email == '') || (!validator.isEmail(@email))
      @emailEditor.addClass 'editor-error'
      isOk = false

    if @password == ''
      @passwordEditor.addClass 'editor-error'
      isOk = false

    isOk


  login: (event, element) ->
    if !@validateInputs()
      return false

    ApiClient ?= require './ApiClient'

    @emailEditor.hiddenInput.attr 'disabled', 'disabled'
    @passwordEditor.hiddenInput.attr 'disabled', 'disabled'
    @loginButton.attr 'disabled', 'disabled'
    @spinner.removeClass 'hidden'

    client = new ApiClient settings.apiUrl
