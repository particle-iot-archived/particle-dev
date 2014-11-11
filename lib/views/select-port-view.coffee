SelectListView = require('atom').SelectListView

$ = null
$$ = null
Subscriber = null
SerialHelper = null

module.exports =
class SelectPortView extends SelectListView
  initialize: (delegate) ->
    super

    {$, $$} = require 'atom'
    {Subscriber} = require 'emissary'

    @subscriber = new Subscriber()
    @subscriber.subscribeToCommand atom.workspaceView, 'core:cancel core:close', => @hide()

    @addClass 'overlay from-top'
    @prop 'id', 'spark-dev-select-port-view'
    @listPortsPromise = null

    @delegate = delegate

  destroy: ->
    @remove()

  show: =>
    if !@hasParent()
      atom.workspaceView.append(this)

      @setItems []
      @setLoading 'Listing ports...'
      @listPorts()
      @focusFilterEditor()

  hide: ->
    if @hasParent()
      @detach()

  viewForItem: (item) ->
    $$ ->
      @li class: 'two-lines', =>
        @div class: 'primary-line', item.serialNumber
        @div class: 'secondary-line', item.comName

  confirmed: (item) ->
    # TODO: Test this
    atom.workspaceView.trigger @delegate, [item.comName]
    @cancel()

  getFilterKey: ->
    'comName'

  listPorts: ->
    SerialHelper = require '../utils/serial-helper'
    @listPortsPromise = SerialHelper.listPorts()
    @listPortsPromise.done (ports) =>
      @setItems ports
      @listPortsPromise = null
