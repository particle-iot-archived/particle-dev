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
        @select outlet: 'ports', mousedown: 'refreshSerialPorts', change: 'portSelected', =>
          @option value: '', 'No port selected'
        @span '@'
        @select outlet: 'baudrates', change: 'baudrateSelected'
        @button class: 'btn icon icon-plug', 'Connect'
      @div class: 'panel-body', outlet: 'variables', =>
        @pre outlet: 'output'
        @subview 'input', new EditorView(mini: true, placeholderText: 'Enter string to send')

  initialize: (serializeState) ->
    {$, $$} = require 'atom'
    SettingsHelper = require '../utils/settings-helper'

    @emitter = new Emitter

    @currentPort = null
    @refreshSerialPorts()

    @currentBaudrate = SettingsHelper.get 'serial_baudrate'
    @currentBaudrate ?= 9600
    @baudratesList = [300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200]
    for baudrate in @baudratesList
      option = $$ ->
        @option value:baudrate, baudrate
      if baudrate == @currentBaudrate
        option.attr 'selected', 'selected'
      @baudrates.append option

  serialize: ->

  refreshSerialPorts: ->
    serialport ?= require 'serialport'
    serialport.list (err, ports) =>
      @ports.find('>').remove()
      @currentPort = SettingsHelper.get 'serial_port'
      for port in ports
        option = $$ ->
          @option value:port.comName, port.comName
        if @currentPort == port.comName
          option.attr 'selected', 'selected'
        @ports.append option

  portSelected: ->
    SettingsHelper.set 'serial_port', @ports.val()

  baudrateSelected: ->
    SettingsHelper.set 'serial_baudrate', @baudrates.val()

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
