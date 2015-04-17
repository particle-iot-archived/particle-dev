SelectListView = require('atom').SelectListView

$ = null
$$ = null
CompositeDisposable = null
SerialHelper = null
SettingsHelper = null
fs = null
path = null

module.exports =
class SelectFirmwareView extends SelectListView
  initialize: ->
    super

    {$, $$} = require 'atom'
    {CompositeDisposable} = require 'atom'
    path ?= require 'path'
    fs ?= require 'fs-plus'

    @disposables = new CompositeDisposable
    @disposables.add atom.commands.add 'atom-workspace',
      'core:cancel': => @hide()
      'core:close': => @hide()

    @addClass 'overlay from-top'
    @prop 'id', 'spark-dev-select-firmware-view'

  destroy: ->
    @remove()

  show: =>
    if !@hasParent()
      atom.workspaceView.append(this)
      @focusFilterEditor()

  hide: ->
    if @hasParent()
      @detach()

  viewForItem: (item) ->
    $$ ->
      stats = fs.statSync item
      @li class: 'two-lines', =>
        @div class: 'primary-line', path.basename(item)
        @div class: 'secondary-line', stats.ctime.toLocaleString()

  confirmed: (item) ->
    atom.workspaceView.trigger 'spark-dev:flash-cloud', [item]
    @cancel()
