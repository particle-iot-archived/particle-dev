{View} = require 'atom-space-pen-views'
SerialHelper = null
Subscriber = null

module.exports =
class ListeningModeView extends View
  @content: ->
    @div =>
      @h1 'Waiting for core...'
      @p =>
        @img src: 'atom://spark-dev/images/listening.gif'
      @p 'Check if your core is connected via USB and it\'s in listening mode (LED blinking blue).'
      @div class: 'block', =>
        @button click: 'cancel', class: 'btn', 'Cancel'

  initialize: (delegate) ->
    {CompositeDisposable} = require 'atom'
    SerialHelper = require '../utils/serial-helper'

    @prop 'id', 'spark-dev-listening-mode-view'
    @panel = atom.workspace.addModalPanel(item: this, visible: false)

    @disposables = new CompositeDisposable
    @workspaceElement = atom.views.getView(atom.workspace)
    @disposables.add atom.commands.add 'atom-workspace',
      'core:cancel', => @cancel()
      'core:close', => @cancel()

    # Interval for automatic dialog dismissal
    @interval = setInterval =>
      promise = SerialHelper.listPorts()
      promise.done (ports) =>
        if ports.length > 0
          # Hide dialog
          @cancel()
          # Try to identify found ports
          atom.commands.dispatch @workspaceElement, delegate
      , (e) =>
        console.error e
    , 1000

  serialize: ->

  destroy: ->
    cancel()
    panelToDestroy = @panel
    @panel = null
    panelToDestroy?.destroy()

  show: ->
    @panel.show()

  hide: ->
    @panel.hide()

  cancel: (event, element) ->
    clearInterval @interval
    @hide()
