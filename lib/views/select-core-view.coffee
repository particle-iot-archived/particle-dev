{SelectView} = require 'particle-dev-views'
packageName = require '../utils/package-helper'

$$ = null

module.exports =
class SelectCoreView extends SelectView
  initialize: ->
    super

    {$$} = require 'atom-space-pen-views'

    @prop 'id', 'select-core-view'
    @addClass packageName()
    @listDevicesPromise = null
    @main = null
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
    device = @main.profileManager.Device.fromApiV1(item)
    @main.profileManager.currentDevice = device

    if typeof item.platform_id != 'undefined'
      @main.profileManager.currentTargetPlatform = item.platform_id
      if item.platform_id == 10 && item.current_build_target
        @main.setCurrentBuildTarget item.current_build_target
    @hide()
    atom.commands.dispatch @workspaceElement, "#{packageName()}:update-core-status"
    atom.commands.dispatch @workspaceElement, "#{packageName()}:update-menu"
    @next(item) if @next

  getFilterKey: ->
    'name'

  loadCores: ->
    @listDevicesPromise = @main.profileManager.apiClient.listDevices()
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
