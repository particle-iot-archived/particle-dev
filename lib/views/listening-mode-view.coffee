{View} = require 'atom'
SerialHelper = null
Subscriber = null

module.exports =
class ListeningModeView extends View
  @content: ->
    @div class: 'overlay from-top', =>
      @h1 'Waiting for core...'
      @p =>
        @img src: 'atom://spark-ide/images/listening.gif'
      @p 'Check if your core is connected via USB and it\'s in listening mode (LED blinking blue).'
      @div class: 'block', =>
        @button click: 'cancel', class: 'btn', 'Cancel'

  initialize: (delegate) ->
    {Subscriber} = require 'emissary'
    SerialHelper = require '../utils/serial-helper'

    @prop 'id', 'spark-ide-listening-mode-view'

    # Interval for automatic dialog dismissal
    @interval = setInterval =>
      promise = SerialHelper.listPorts()
      promise.done (ports) =>
        if ports.length > 0
          # Hide dialog
          atom.workspaceView.trigger 'core:cancel'
          # Try to identify found ports
          console.log 'deleg', delegate
          atom.workspaceView.trigger delegate
    , 1000

    # Subscribe to Atom's core:cancel core:close events
    @subscriber = new Subscriber()
    @subscriber.subscribeToCommand atom.workspaceView, 'core:cancel core:close', ({target}) =>
      clearInterval @interval
      @hide()

  serialize: ->

  destroy: ->
    @detach()

  show: ->
    if !@hasParent()
      atom.workspaceView.append(this)

  hide: ->
    if @hasParent()
      @detach()

  cancel: (event, element) ->
    atom.workspaceView.trigger 'core:cancel'
