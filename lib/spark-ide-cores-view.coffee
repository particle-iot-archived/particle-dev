SelectListView = require('atom').SelectListView

$ = null
$$ = null
ApiClient = null
settings = null

module.exports =
class SparkIdeCoresView extends SelectListView
  initialize: ->
    super

    {$, $$} = require 'atom'
    settings = require './settings'

    @addClass 'overlay from-top'
    @listDevicesPromise = null


  destroy: ->
    @remove()

  show: =>
    if !@hasParent()
      atom.workspaceView.append(this)

      @setItems []
      @setLoading 'Loading cores...'
      @loadCores()
      @focusFilterEditor()

  hide: ->
    if @hasParent()
      @detach()

  # Here you specify the view for an item
  viewForItem: (item) ->
    $$ ->
      @li class: 'two-lines core-line', =>
        @div class: 'primary-line ' + (if item.connected then 'core-online' else 'core-offline'), item.name
        @div class: 'secondary-line no-icon', item.id

  confirmed: (item) ->
    settings.current_core = item.id
    settings.override null, 'current_core', settings.current_core

    settings.current_core_name = item.name
    settings.override null, 'current_core_name', settings.current_core_name

    @cancel()
    atom.workspaceView.trigger 'spark-ide:update-core-status'

  getFilterKey: ->
    'name'

  loadCores: ->
    ApiClient = require './ApiClient'
    client = new ApiClient settings.apiUrl, settings.access_token

    @listDevicesPromise = client.listDevices()
    @listDevicesPromise.done (e) =>
      @setItems e
      @listDevicesPromise = null
    , (e) =>
      console.log e
      # TODO: Error handling
      @listDevicesPromise = null
