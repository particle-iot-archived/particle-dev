{View, EditorView} = require 'atom'

$ = null
_s = null
Subscriber = null
spark = null
SettingsHelper = null
validator = null

module.exports =
class WifiCredentialsView extends View
  @content: ->
    @div id: 'spark-ide-wifi-credentials-view', class: 'overlay from-top', =>
      @div class: 'block', =>
        @span 'Enter WiFi Credentials '
        @span class: 'text-subtle', =>
          @text 'Close this dialog with the '
          @span class: 'highlight', 'esc'
          @span ' key'
      @subview 'ssidEditor', new EditorView(mini: true, placeholderText: 'SSID')
      @div class: 'security', =>
        @label =>
          @input type: 'radio', name: 'security', value: 'unsecured', checked: 'checked', change: 'change'
          @span 'Unsecured'
        @label =>
          @input type: 'radio', name: 'security', value: 'wep', change: 'change'
          @span 'WEP'
        @label =>
          @input type: 'radio', name: 'security', value: 'wpa', change: 'change'
          @span 'WPA'
        @label =>
          @input type: 'radio', name: 'security', value: 'wpa2', change: 'change'
          @span 'WPA2'
      @subview 'passwordEditor', new EditorView(mini: true, placeholderText: 'and a password?')
      @div class: 'text-error block', outlet: 'errorLabel'
      @div class: 'block', =>
        @button click: 'save', id: 'saveButton', class: 'btn btn-primary', outlet: 'saveButton', 'Save'
        @button click: 'cancel', id: 'cancelButton', class: 'btn', outlet: 'cancelButton', 'Cancel'
        @span class: 'three-quarters inline-block hidden', outlet: 'spinner'

  initialize: (serializeState) ->
    {Subscriber} = require 'emissary'
    $ ?= require('atom').$

    _s ?= require 'underscore.string'
    SettingsHelper = require '../utils/settings-helper'

    @subscriber = new Subscriber()
    @subscriber.subscribeToCommand atom.workspaceView, 'core:cancel core:close', ({target}) =>
      @remove()

    @security = 'unsecured'
    @passwordEditor.addClass 'hidden'


  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @remove()

  show: (ssid=null, security=null) =>
    if !@hasParent()
      atom.workspaceView.append(this)
      @ssidEditor.getEditor().setText ssid

      if security
        input = @find 'input[name=security][value=' + security + ']'
        input.attr 'checked', 'checked'
        input.change()

      @errorLabel.hide()
      if !ssid
        @ssidEditor.focus()

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
    @ssidEditor.removeClass 'editor-error'
    @passwordEditor.removeClass 'editor-error'

  change: ->
    @security = @find('input[name=security]:checked').val()

    if @security == 'unsecured'
      @passwordEditor.addClass 'hidden'
    else
      @passwordEditor.removeClass 'hidden'
      @passwordEditor.focus()

  # Test input's values
  validateInputs: ->
    validator ?= require 'validator'

    @clearErrors()

    @ssid = _s.trim(@ssidEditor.getText())
    @password = _s.trim(@passwordEditor.getText())

    isOk = true

    if @ssid == ''
      @ssidEditor.addClass 'editor-error'
      isOk = false

    if @password == ''
      @passwordEditor.addClass 'editor-error'
      isOk = false

    isOk

  # Unlock inputs and buttons
  unlockUi: ->
    @ssidEditor.hiddenInput.removeAttr 'disabled'
    @passwordEditor.hiddenInput.removeAttr 'disabled'
    @saveButton.removeAttr 'disabled'
