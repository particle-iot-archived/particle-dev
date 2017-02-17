{SelectView} = require 'particle-dev-views'
packageName = require '../utils/package-helper'

$$ = null
SettingsHelper = null
semver = null

module.exports =
class SelectBuildTargetView extends SelectView
  initialize: ->
    super

    {$$} = require 'atom-space-pen-views'
    SettingsHelper = require '../utils/settings-helper'

    @prop 'id', 'select-build-target-view'
    @addClass packageName()
    @listBuildTargetsPromise = null
    @main = null
    @requestErrorHandler = null

  show: (next=null) =>
    @setItems []
    @next = next
    @setLoading 'Loading build targets...'
    @loadBuildTargets()
    super

  # Here you specify the view for an item
  viewForItem: (item) ->
    $$ ->
      @li =>
        @div =>
          @span item.version
          if item.prerelease
            @div class: 'pull-right', =>
              @span class: 'icon icon-alert status-modified', title: 'This is a pre-release'

  confirmed: (item) ->
    @main.setCurrentBuildTarget item.version
    @hide()
    atom.commands.dispatch @workspaceElement, "#{packageName()}:update-build-target"

  getFilterKey: ->
    'version'

  loadBuildTargets: ->
    @listBuildTargetsPromise = @main.getBuildTargets()
    @listBuildTargetsPromise.then (targets) =>
      @setItems targets
      @listDevicesPromise = null
    , (e) =>
      @listDevicesPromise = null
      @requestErrorHandler e
