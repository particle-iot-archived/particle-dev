{View, $} = require 'atom-space-pen-views'
{MiniEditorView} = require 'spark-dev-views'

$ = null
_s = null
SettingsHelper = null
validator = null
SerialHelper = null

module.exports =
class WifiCredentialsView extends View
  @content: ->
    @div id: 'spark-dev-wifi-credentials-view', =>
      @div class: 'block', =>
        @span 'Enter WiFi Credentials '
        @span class: 'text-subtle', =>
          @text 'Close this dialog with the '
          @span class: 'highlight', 'esc'
          @span ' key'
      @subview 'ssidEditor', new MiniEditorView('SSID')
      @div class: 'security', =>
        @label =>
          @input type: 'radio', name: 'security', value: '0', checked: 'checked', change: 'change'
          @span 'Unsecured'
        @label =>
          @input type: 'radio', name: 'security', value: '1', change: 'change'
          @span 'WEP'
        @label =>
          @input type: 'radio', name: 'security', value: '2', change: 'change'
          @span 'WPA'
        @label =>
          @input type: 'radio', name: 'security', value: '3', change: 'change'
          @span 'WPA2'
      @subview 'passwordEditor', new MiniEditorView('and a password?')
      @div class: 'text-error block', outlet: 'errorLabel'
      @div class: 'block', =>
        @button click: 'save', id: 'saveButton', class: 'btn btn-primary', outlet: 'saveButton', 'Save'
        @button click: 'cancel', id: 'cancelButton', class: 'btn', outlet: 'cancelButton', 'Cancel'
        @span class: 'three-quarters inline-block hidden', outlet: 'spinner'

  initialize: (serializeState) ->
    {CompositeDisposable} = require 'atom'
    _s ?= require 'underscore.string'
    SettingsHelper = require '../utils/settings-helper'
    SerialHelper = require '../utils/serial-helper'

    @panel = atom.workspace.addModalPanel(item: this, visible: false)
    @workspaceElement = atom.views.getView(atom.workspace)

    @disposables = new CompositeDisposable
    @disposables.add atom.commands.add 'atom-workspace',
      'core:cancel', => @remove()
      'core:close', => @remove()

    @disposables.add atom.commands.add @passwordEditor.editor.element,
      'core:confirm': =>
        @save()

    @security = '0'
    @passwordEditor.addClass 'hidden'

    @serialWifiConfigPromise = null


  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    panelToDestroy = @panel
    @panel = null
    panelToDestroy?.destroy()

    @disposables.dispose()

  show: (ssid=null, security=null) =>
    @panel.show()
    if ssid
      @ssidEditor.editor.getModel().setText ssid
    else
      @ssidEditor.editor.click()

    if security
      input = @find 'input[name=security][value=' + security + ']'
      input.attr 'checked', 'checked'
      input.change()

    @errorLabel.hide()

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
    @ssidEditor.editor.removeClass 'editor-error'
    @passwordEditor.editor.removeClass 'editor-error'

  change: ->
    @security = @find('input[name=security]:checked').val()

    if @security == '0'
      @passwordEditor.addClass 'hidden'
    else
      @passwordEditor.removeClass 'hidden'
      @passwordEditor.editor.click()

  # Test input's values
  validateInputs: ->
    validator ?= require 'validator'

    @clearErrors()

    @ssid = _s.trim(@ssidEditor.editor.getModel().getText())
    @password = _s.trim(@passwordEditor.editor.getModel().getText())

    isOk = true

    if @ssid == ''
      @ssidEditor.editor.addClass 'editor-error'
      isOk = false

    if (@security != '0') && (@password == '')
      @passwordEditor.editor.addClass 'editor-error'
      isOk = false

    isOk

  # Unlock inputs and buttons
  unlockUi: ->
    @ssidEditor.setEnabled true
    @find('input[name=security]').removeAttr 'disabled'
    @passwordEditor.setEnabled true
    @saveButton.removeAttr 'disabled'

  save: ->
    if !@validateInputs()
      return false

    @ssidEditor.setEnabled false
    @find('input[name=security]').attr 'disabled', 'disabled'
    @passwordEditor.setEnabled false
    @saveButton.attr 'disabled', 'disabled'
    @spinner.removeClass 'hidden'
    @errorLabel.hide()

    @serialWifiConfigPromise = SerialHelper.serialWifiConfig @port, @ssid, @password, @security
    @serialWifiConfigPromise.done (e) =>
      @spinner.addClass 'hidden'

      @cancel()
      @serialWifiConfigPromise = null
    , (e) =>
      @spinner.addClass 'hidden'
      @unlockUi()
      @errorLabel.text(e).show()
      @serialWifiConfigPromise = null
