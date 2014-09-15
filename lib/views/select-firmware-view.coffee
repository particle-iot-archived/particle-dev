SelectListView = require('atom').SelectListView

$ = null
$$ = null
Subscriber = null
SerialHelper = null
SettingsHelper = null
fs = null
path = null

module.exports =
class SelectFirmwareView extends SelectListView
  initialize: ->
    super

    {$, $$} = require 'atom'
    {Subscriber} = require 'emissary'
    path ?= require 'path'
    fs ?= require 'fs-plus'

    @subscriber = new Subscriber()
    @subscriber.subscribeToCommand atom.workspaceView, 'core:cancel core:close', => @hide()

    @addClass 'overlay from-top'
    @prop 'id', 'spark-ide-select-firmware-view'

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
    atom.workspaceView.trigger 'spark-ide:flash-cloud', [item]
    @cancel()
