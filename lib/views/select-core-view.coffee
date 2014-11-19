SelectListView = require('atom').SelectListView

$ = null
$$ = null
spark = null
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
    @prop 'id', 'spark-dev-select-core-view'
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
    name = item.name
    if !name
      name = 'Unnamed'
      
    $$ ->
      @li class: 'two-lines core-line', =>
        @div class: 'primary-line ' + (if item.connected then 'core-online' else 'core-offline'), name
        @div class: 'secondary-line no-icon', item.id

  confirmed: (item) ->
    SettingsHelper.setCurrentCore item.id, item.name

    atom.workspaceView.trigger 'spark-dev:update-core-status'
    atom.workspaceView.trigger 'spark-dev:update-menu'

    @cancel()

  getFilterKey: ->
    'name'

  loadCores: ->
    spark ?= require 'spark'
    spark.login { accessToken: SettingsHelper.get('access_token') }

    @listDevicesPromise = spark.listDevices()
    @listDevicesPromise.done (e) =>
      @setItems e
      @listDevicesPromise = null
    , (e) =>
      # TODO: Error handling
      @listDevicesPromise = null
