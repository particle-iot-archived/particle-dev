{SelectView} = require 'spark-dev-views'

$$ = null
spark = null
Subscriber = null
SettingsHelper = null

module.exports =
class SelectCoreView extends SelectView
  initialize: ->
    super

    {$$} = require 'atom-space-pen-views'
    SettingsHelper = require '../utils/settings-helper'

    @prop 'id', 'spark-dev-select-core-view'
    @listDevicesPromise = null

  show: =>
    @setItems []
    @setLoading 'Loading devices...'
    @loadCores()
    super

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
    @hide()
    atom.commands.dispatch @workspaceElement, 'spark-dev:update-core-status'
    atom.commands.dispatch @workspaceElement, 'spark-dev:update-menu'

  getFilterKey: ->
    'name'

  loadCores: ->
    spark ?= require 'spark'
    spark.login { accessToken: SettingsHelper.get('access_token') }

    @listDevicesPromise = spark.listDevices()
    @listDevicesPromise.done (e) =>
      e.sort (a, b) =>
        if !a.name
          a.name = ''
        if !b.name
          b.name = ''
        order = (b.connected - a.connected) * 1000
        if a.name.toLowerCase() < b.name.toLowerCase()
          order -= 1
        else if a.name.toLowerCase() > b.name.toLowerCase()
          order += 1
        order
      @setItems e
      @listDevicesPromise = null
    , (e) =>
      # TODO: Error handling
      @listDevicesPromise = null
