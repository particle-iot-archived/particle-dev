{SelectView} = require 'particle-dev-views'
packageName = require '../utils/package-helper'

$$ = null
SettingsHelper = null

module.exports =
class SelectCoreView extends SelectView
  initialize: ->
    super

    {$$} = require 'atom-space-pen-views'
    SettingsHelper = require '../utils/settings-helper'

    @prop 'id', 'select-core-view'
    @addClass packageName()
    @listDevicesPromise = null
    @profileManager = null
    @requestErrorHandler = null

  show: (next=null) =>
    @setItems []
    @next = next
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
        connectedClass = if item.connected then 'core-online' else 'core-offline'
        @div class: 'primary-line ' + connectedClass, =>
          @span class: 'platform-icon platform-icon-' + item.platform_id, name
        @div class: 'secondary-line no-icon', item.id

  confirmed: (item) ->
    SettingsHelper.setCurrentCore item.id, item.name, item.platform_id, item.default_build_target
    if item.platform_id
      @profileManager.currentTargetPlatform = item.platform_id
    @hide()
    atom.commands.dispatch @workspaceElement, "#{packageName()}:update-core-status"
    atom.commands.dispatch @workspaceElement, "#{packageName()}:update-menu"
    @next(item) if @next

  getFilterKey: ->
    'name'

  loadCores: ->
    @listDevicesPromise = @profileManager.apiClient.listDevices()
    @listDevicesPromise.then (value) =>
      e = value.body
      e.sort (a, b) ->
        if !a.name
          a.name = 'Unnamed'
        if !b.name
          b.name = 'Unnamed'
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
      @requestErrorHandler e
