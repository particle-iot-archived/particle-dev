{SelectListView} = require 'atom-space-pen-views'

$ = null
$$ = null
spark = null
Subscriber = null
SettingsHelper = null

module.exports =
class SelectCoreView extends SelectListView
  initialize: ->
    super

    {$, $$} = require 'atom-space-pen-views'
    {CompositeDisposable} = require 'atom'
    SettingsHelper = require '../utils/settings-helper'

    @panel = atom.workspace.addModalPanel(item: this, visible: false)

    @disposables = new CompositeDisposable
    @workspaceElement = atom.views.getView(atom.workspace)
    @disposables.add atom.commands.add 'atom-workspace',
      'core:cancel', =>
        @hide()
      'core:close', =>
        @hide()

    @addClass 'overlay from-top'
    @prop 'id', 'spark-dev-select-core-view'
    @listDevicesPromise = null

  destroy: ->
    @panel.hide()
    @disposables.dispose()

  show: =>
    @panel.show()

    @setItems []
    @setLoading 'Loading devices...'
    @loadCores()
    @focusFilterEditor()

  hide: ->
    @panel.hide()

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

    atom.commands.dispatch @workspaceElement, 'spark-dev:update-core-status'
    atom.commands.dispatch @workspaceElement, 'spark-dev:update-menu'

    @hide()

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
