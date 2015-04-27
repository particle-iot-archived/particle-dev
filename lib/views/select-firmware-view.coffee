{SelectListView} = require 'atom-space-pen-views'

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

    {$, $$} = require 'atom-space-pen-views'
    {CompositeDisposable, Emitter} = require 'atom'
    path ?= require 'path'
    fs ?= require 'fs-plus'

    @panel = atom.workspace.addModalPanel(item: this, visible: false)

    @disposables = new CompositeDisposable
    @workspaceElement = atom.views.getView(atom.workspace)

    @prop 'id', 'spark-dev-select-firmware-view'

  destroy: ->
    @hide()
    @disposables.dispose()

  cancelled: ->
    @hide()

  show: =>
    @panel.show()
    @focusFilterEditor()

  hide: ->
    @panel.hide()

  viewForItem: (item) ->
    $$ ->
      stats = fs.statSync item
      @li class: 'two-lines', =>
        @div class: 'primary-line', path.basename(item)
        @div class: 'secondary-line', stats.ctime.toLocaleString()

  confirmed: (item) ->
    hide()
    atom.sparkDev.emitter.emit 'spark-dev:flash-cloud',
      firmware: item
