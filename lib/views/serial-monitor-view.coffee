{View} = require 'atom-space-pen-views'
{Disposable, CompositeDisposable} = require 'atom'
{MiniEditorView} = require 'particle-dev-views'
packageName = require '../utils/package-helper'

$ = null
$$ = null
SettingsHelper = null
serialport = null

module.exports =
class SerialMonitorView extends View
  @content: ->
    @div id: 'serial-monitor', class: 'panel ' + packageName(), =>
      @div class: 'panel-heading', =>
        @select outlet: 'portsSelect', change: 'portSelected', =>
          @option value: '', 'No port selected'
        @button class: 'btn icon-sync', id: 'refresh-ports-button', outlet: 'refreshPortsButton', click: 'refreshSerialPorts', ''
        @span '@'
        @select outlet: 'baudratesSelect', change: 'baudrateSelected'
        @button class: 'btn', outlet: 'connectButton', click: 'toggleConnect', 'Connect'
        @button class: 'btn pull-right', click: 'clearOutput', 'Clear'
      @div class: 'panel-body', outlet: 'variables', =>
        @pre outlet: 'output'
        @subview 'input', new MiniEditorView('Enter string to send')

  initialize: (serializeState) ->
    {$, $$} = require 'atom-space-pen-views'
    SettingsHelper = require '../utils/settings-helper'

    @disposables = new CompositeDisposable

    @currentPort = null
    @refreshSerialPorts()

    @currentBaudrate = SettingsHelper.get 'serial_baudrate'
    @currentBaudrate ?= 9600
    @currentBaudrate = parseInt @currentBaudrate

    @baudratesList = [300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200]
    for baudrate in @baudratesList
      option = $$ ->
        @option value:baudrate, baudrate
      if baudrate == @currentBaudrate
        option.attr 'selected', 'selected'
      @baudratesSelect.append option

    @port = null

    @disposables.add atom.commands.add @input.editor.element,
      'core:confirm': =>
        if @isPortOpen()
          @port.write @input.editor.getText() + "\n"
          @input.editor.setText ''
    @input.setEnabled false

  destroy: ->
    @disposables?.dispose()

  serialize: ->

  getTitle: ->
    'Serial monitor'

  # TODO: Remove both of these post 1.0
  onDidChangeTitle: (callback) -> new Disposable()
  onDidChangeModified: (callback) -> new Disposable()

  getUri: ->
    "#{packageName()}://editor/serial-monitor"

  close: ->
    pane = atom.workspace.paneForUri @getUri()
    pane?.destroy()

  escapeHtml: (unsafe) ->
    unsafe
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;")

  appendText: (text, appendNewline=true) ->
    at_bottom = (@output.scrollTop() + @output.innerHeight() + 10 > @output[0].scrollHeight)

    text = @escapeHtml text
    text = text.replace "\r", ''
    if appendNewline
      text += "\n"
    @output.html(@output.html() + text)

    if at_bottom
      @output.scrollTop(@output[0].scrollHeight)

  refreshSerialPorts: ->
    serialport ?= require 'serialport'
    serialport.list (err, ports) =>
      @portsSelect.find('>').remove()
      @currentPort = SettingsHelper.get 'serial_port'
      for port in ports
        option = $$ ->
          @option value:port.comName, port.comName
        if @currentPort == port.comName
          option.attr 'selected', 'selected'
        @portsSelect.append option

      if ports.length > 0
        @currentPort ?= ports[0].comName
        SettingsHelper.set 'serial_port', @currentPort

  portSelected: ->
    @currentPort = @portsSelect.val()
    SettingsHelper.set 'serial_port', @currentPort

  baudrateSelected: ->
    @currentBaudrate = @baudratesSelect.val()
    SettingsHelper.set 'serial_baudrate', @currentBaudrate

  toggleConnect: ->
    if !!@portsSelect.attr 'disabled'
      @disconnect()
    else
      @connect()

  isPortOpen: ->
    @port?.fd && parseInt(@port.fd) >= 0

  connect: ->
    @portsSelect.attr 'disabled', 'disabled'
    @refreshPortsButton.attr 'disabled', 'disabled'
    @baudratesSelect.attr 'disabled', 'disabled'
    @connectButton.text 'Disconnect'
    @input.setEnabled true

    @port = new serialport.SerialPort @currentPort, {
      baudrate: @currentBaudrate
    }, false

    @port?.on 'close', =>
      @disconnect()

    @port?.on 'error', (e) =>
      console.error e
      @disconnect()

    @port?.on 'data', (data) =>
      @appendText data.toString(), false

    @port?.open()
    @input.editor.element.focus()

  disconnect: ->
    @portsSelect.removeAttr 'disabled'
    @refreshPortsButton.removeAttr 'disabled'
    @baudratesSelect.removeAttr 'disabled'
    @connectButton.text 'Connect'
    @input.setEnabled false

    if @isPortOpen()
      @port.close()

  clearOutput: ->
    @output.html ''

  # Method used only in tests
  nullifySerialport: ->
    serialport = null
