{View, TextEditorView} = require 'atom'

$ = null
_s = null
Subscriber = null
spark = null
SettingsHelper = null
validator = null

module.exports =
class LoginView extends View
  @content: ->
    @div id: 'spark-dev-login-view', class: 'overlay from-top', =>
      @div class: 'block', =>
        @span 'Log in to Spark Cloud '
        @span class: 'text-subtle', =>
          @text 'Close this dialog with the '
          @span class: 'highlight', 'esc'
          @span ' key'
      @subview 'emailEditor', new TextEditorView(mini: true, placeholderText: 'Could I please have an email address?')
      @subview 'passwordEditor', new TextEditorView(mini: true, placeholderText: 'and a password?')
      @div class: 'text-error block', outlet: 'errorLabel'
      @div class: 'block', =>
        @button click: 'login', id: 'loginButton', class: 'btn btn-primary', outlet: 'loginButton', 'Log in'
        @button click: 'cancel', id: 'cancelButton', class: 'btn', outlet: 'cancelButton', 'Cancel'
        @span class: 'three-quarters inline-block hidden', outlet: 'spinner'
        @a href: 'https://www.spark.io/forgot-password', class: 'pull-right', 'Forgot password?'

  initialize: (serializeState) ->
    {Subscriber} = require 'emissary'
    $ ?= require('atom').$

    _s ?= require 'underscore.string'
    SettingsHelper = require '../utils/settings-helper'

    @subscriber = new Subscriber()
    @subscriber.subscribeToCommand atom.workspaceView, 'core:cancel core:close', ({target}) =>
      atom.workspaceView.trigger 'spark-dev:cancel-login'

    @loginPromise = null

    # As Atom doesn't provide password input, we have to hack TextEditorView to act as one
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

  # Remove errors from inputs
  clearErrors: ->
    @emailEditor.removeClass 'editor-error'
    @passwordEditor.removeClass 'editor-error'

  # Test input's values
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

  # Unlock inputs and buttons
  unlockUi: ->
    @emailEditor.hiddenInput.removeAttr 'disabled'
    @passwordEditor.hiddenInput.removeAttr 'disabled'
    @loginButton.removeAttr 'disabled'

  # Login via the cloud
  login: (event, element) =>
    if !@validateInputs()
      return false

    @emailEditor.hiddenInput.attr 'disabled', 'disabled'
    @passwordEditor.hiddenInput.attr 'disabled', 'disabled'
    @loginButton.attr 'disabled', 'disabled'
    @spinner.removeClass 'hidden'
    @errorLabel.hide()

    spark = require 'spark'
    @loginPromise = spark.login { username:@email, password:@password }
    @loginPromise.done (e) =>
      @spinner.addClass 'hidden'
      if !@loginPromise
        return
      SettingsHelper.setCredentials @email, e.access_token
      atom.workspaceView.trigger 'spark-dev:update-login-status'
      @loginPromise = null

      @cancel()

    , (e) =>
      @spinner.addClass 'hidden'
      if !@loginPromise
        return
      @unlockUi()
      if e.code == 'ENOTFOUND'
        @errorLabel.text 'Error while connecting to ' + e.hostname
      else
        @errorLabel.text e

      @errorLabel.show()
      @loginPromise = null

  # Logout
  logout: =>
    SettingsHelper.clearCredentials()
    atom.workspaceView.trigger 'spark-dev:update-login-status'
