SelectListView = require('atom').SelectListView

$ = null
$$ = null
ApiClient = null
Subscriber = null
SettingsHelper = null

module.exports =
class SelectCoreView extends SelectListView
  initialize: ->
    super

    {$, $$} = require 'atom'
    {Subscriber} = require 'emissary'
    SettingsHelper = require '../utils/settings-helper'

    @subscriber = new Subscriber()
    @subscriber.subscribeToCommand atom.workspaceView, 'core:cancel core:close', => @hide()

    @addClass 'overlay from-top'
    @attr 'id', 'spark-ide-cores-view'
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
    SettingsHelper.setCurrentCore item.id, item.name

    @cancel()
    atom.workspaceView.trigger 'spark-ide:update-core-status'

  getFilterKey: ->
    'name'

  loadCores: ->
    ApiClient = require '../vendor/ApiClient'
    client = new ApiClient SettingsHelper.get('apiUrl'), SettingsHelper.get('access_token')

    @listDevicesPromise = client.listDevices()
    @listDevicesPromise.done (e) =>
      @setItems e
      @listDevicesPromise = null
    , (e) =>
      console.log e
      # TODO: Error handling
      @listDevicesPromise = null
