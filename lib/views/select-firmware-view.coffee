{SelectView} = require 'spark-dev-views'

$$ = null
SerialHelper = null
SettingsHelper = null
fs = null
path = null

module.exports =
class SelectFirmwareView extends SelectView
  initialize: ->
    super

    {$$} = require 'atom-space-pen-views'
    path ?= require 'path'
    fs ?= require 'fs-plus'

    @prop 'id', 'spark-dev-select-firmware-view'

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
