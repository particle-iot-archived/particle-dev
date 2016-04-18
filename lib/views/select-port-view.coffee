{SelectView} = require 'particle-dev-views'

$$ = null
Subscriber = null
SerialHelper = null

module.exports =
class SelectPortView extends SelectView
  initialize: (delegate) ->
    super

    {$$} = require 'atom-space-pen-views'

    @prop 'id', 'spark-dev-select-port-view'
    @listPortsPromise = null
    @delegate = delegate

  show: =>
    @setItems []
    @setLoading 'Listing ports...'
    @listPorts()
    super

  viewForItem: (item) ->
    $$ ->
      @li class: 'two-lines', =>
        @div class: 'primary-line', item.serialNumber
        @div class: 'secondary-line', item.comName

  confirmed: (item) ->
    @hide()
    # TODO: Cover it with tests
    atom.sparkDev.emitter.emit @delegate,
      port: item.comName

  getFilterKey: ->
    'comName'

  listPorts: ->
    SerialHelper = require '../utils/serial-helper'
    @listPortsPromise = SerialHelper.listPorts()
    @listPortsPromise.then (ports) =>
      @setItems ports
      @listPortsPromise = null
    , (e) =>
      console.error e
