{View, EditorView} = require 'atom'
{Emitter} = require 'event-kit'
$ = null
$$ = null
SettingsHelper = null
serialport = null

module.exports =
class SerialMonitorView extends View
  @content: ->
    @div id: 'spark-ide-serial-monitor', class: 'panel', =>
      @div class: 'panel-heading', =>
        @select outlet: 'portsSelect', mousedown: 'refreshSerialPorts', change: 'portSelected', =>
          @option value: '', 'No port selected'
        @span '@'
        @select outlet: 'baudratesSelect', change: 'baudrateSelected'
        @button class: 'btn', outlet: 'connectButton', click: 'toggleConnect', 'Connect'
        @button class: 'btn pull-right', click: 'clearOutput', 'Clear'
      @div class: 'panel-body', outlet: 'variables', =>
        @pre outlet: 'output'
        @subview 'input', new EditorView(mini: true, placeholderText: 'Enter string to send')

  initialize: (serializeState) ->
    {$, $$} = require 'atom'
    SettingsHelper = require '../utils/settings-helper'

    @emitter = new Emitter

    @currentPort = null
    @refreshSerialPorts()

    @currentBaudrate = parseInt(SettingsHelper.get 'serial_baudrate')
    @currentBaudrate ?= 9600
    @baudratesList = [300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200]
    for baudrate in @baudratesList
      option = $$ ->
        @option value:baudrate, baudrate
      if baudrate == @currentBaudrate
        option.attr 'selected', 'selected'
      @baudratesSelect.append option

    @port = null

  serialize: ->

  getTitle: ->
    'Serial monitor'

  onDidChangeTitle: (callback) ->
    @emitter.on 'did-change-title', callback

  onDidChangeModified: (callback) ->
    @emitter.on 'did-change-modified', callback

  getUri: ->
    'spark-ide://editor/serial-monitor'

  close: ->
    pane = atom.workspace.paneForUri @getUri()
    pane.destroy()

  appendText: (text, appendNewline=true) ->
    at_bottom = (@output.scrollTop() + @output.innerHeight() + 10 > @output[0].scrollHeight)

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

  connect: ->
    @portsSelect.attr 'disabled', 'disabled'
    @baudratesSelect.attr 'disabled', 'disabled'
    @connectButton.text 'Disconnect'

    @port = new serialport.SerialPort @currentPort, {
      baudrate: @currentBaudrate
    }, false

    @port.on 'close', =>
      @disconnect()

    @port.on 'error', (e) =>
      # FIXME: Connecting first time throws an error. Check if this is caused by node-pre-gyp
      console.log 'error', e
      @disconnect()

    @port.on 'data', (data) =>
      @appendText data.toString(), false

    @port.open()

  disconnect: ->
    @portsSelect.removeAttr 'disabled'
    @baudratesSelect.removeAttr 'disabled'
    @connectButton.text 'Connect'

    if @port.fd && parseInt(@port.fd) >= 0
      @port.close()

  clearOutput: ->
    @output.html ''
