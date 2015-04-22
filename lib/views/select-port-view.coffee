{SelectListView} = require 'atom-space-pen-views'

$ = null
$$ = null
Subscriber = null
SerialHelper = null

module.exports =
class SelectPortView extends SelectListView
  initialize: (delegate) ->
    super

    {$, $$} = require 'atom-space-pen-views'
    {CompositeDisposable, Emitter} = require 'atom'

    @panel = atom.workspace.addModalPanel(item: this, visible: false)

    @disposables = new CompositeDisposable
    @emitter = new Emitter

    @workspaceElement = atom.views.getView(atom.workspace)
    @disposables.add atom.commands.add 'atom-workspace',
      'core:cancel', =>
        @hide()
      'core:close', =>
        @hide()

    @addClass 'overlay from-top'
    @prop 'id', 'spark-dev-select-port-view'
    @listPortsPromise = null

    @delegate = delegate

  destroy: ->
    @panel.hide()
    @disposables.dispose()

  show: =>
    @panel.show()

    @setItems []
    @setLoading 'Listing ports...'
    @listPorts()
    @focusFilterEditor()

  hide: ->
    @panel.hide()

  viewForItem: (item) ->
    $$ ->
      @li class: 'two-lines', =>
        @div class: 'primary-line', item.serialNumber
        @div class: 'secondary-line', item.comName

  confirmed: (item) ->
    # TODO: Cover it with tests
    @emitter.emit @delegate,
      port: item.comName
    @cancel()

  getFilterKey: ->
    'comName'

  listPorts: ->
    SerialHelper = require '../utils/serial-helper'
    @listPortsPromise = SerialHelper.listPorts()
    @listPortsPromise.done (ports) =>
      @setItems ports
      @listPortsPromise = null
    , (e) =>
      console.error e
