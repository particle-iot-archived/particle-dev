{View, EditorView} = require 'atom'

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
      @subview 'emailEditor', new EditorView(mini: true, placeholderText: 'Could I please have an email address?')
      @subview 'passwordEditor', new EditorView(mini: true, placeholderText: 'and a password?')
      @div class: 'text-error block', outlet: 'errorLabel'
      @div class: 'block', =>
        @button click: 'login', id: 'loginButton', class: 'btn btn-primary', outlet: 'loginButton', 'Log in'
        @button click: 'cancel', id: 'cancelButton', class: 'btn', outlet: 'cancelButton', 'Cancel'
        @span class: 'loading loading-spinner-tiny inline-block hidden', outlet: 'spinner'
        @a href: 'https://www.spark.io/forgot-password', class: 'pull-right', 'Forgot password?'

  initialize: (serializeState) ->
    {Subscriber} = require 'emissary'
    $ = require('atom').$

    _s = require 'underscore.string'
    settings = require './settings'

    @subscriber = new Subscriber()
    @subscriber.subscribeToCommand atom.workspaceView, 'core:cancel core:close', ({target}) =>
      atom.workspaceView.trigger 'spark-ide:cancel-login'

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
      else if e.which == 13
        @login()
      true

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @remove()

  show: =>
    if !@hasParent()
      atom.workspaceView.append(this)
      @emailEditor.getEditor().setText ''
      @passwordEditor.getEditor().setText ''
      @passwordEditor.originalText = ''
      @errorLabel.hide()
      @emailEditor.focus()

  hide: ->
    if @hasParent()
      @detach()

  cancel: (event, element) =>
    if !!@loginPromise
      @loginPromise = null
    @unlockUi()
    @clearErrors()
    @hide()

  cancelCommand: ->
    @cancel()

  clearErrors: ->
    @emailEditor.removeClass 'editor-error'
    @passwordEditor.removeClass 'editor-error'

  validateInputs: ->
    validator ?= require 'validator'

    @clearErrors()

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

  unlockUi: ->
    @emailEditor.hiddenInput.removeAttr 'disabled'
    @passwordEditor.hiddenInput.removeAttr 'disabled'
    @loginButton.removeAttr 'disabled'

  login: (event, element) =>
    if !@validateInputs()
      return false

    # It should be ?= instead of = to save time but then the tests won't work
    # as ApiClient could be set in one of the previous tests
    ApiClient = require './ApiClient'
    @emailEditor.hiddenInput.attr 'disabled', 'disabled'
    @passwordEditor.hiddenInput.attr 'disabled', 'disabled'
    @loginButton.attr 'disabled', 'disabled'
    @spinner.removeClass 'hidden'
    @errorLabel.hide()
    
    client = new ApiClient settings.apiUrl
    @loginPromise = client.login 'spark-ide', @email, @password
    @loginPromise.done (e) =>
      @spinner.addClass 'hidden'
      if !@loginPromise
        return

      settings.username = @email
      settings.override null, 'username', settings.username
      settings.access_token = e
      settings.override null, 'access_token', settings.access_token
      atom.workspaceView.trigger 'spark-ide:update-login-status'
      @loginPromise = null
      @cancel()

    , (e) =>
      @spinner.addClass 'hidden'
      if !@loginPromise
        return
      @unlockUi()
      @errorLabel.text(e).show()
      @loginPromise = null

  logout: =>
    settings.username = null
    settings.override null, 'username', settings.username
    settings.access_token = null
    settings.override null, 'access_token', settings.access_token
    atom.workspaceView.trigger 'spark-ide:update-login-status'
