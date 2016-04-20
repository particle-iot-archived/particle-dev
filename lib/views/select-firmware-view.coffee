{SelectView} = require 'particle-dev-views'
packageName = require '../utils/package-helper'

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

    @prop 'id', 'select-firmware-view'
    @addClass packageName()

  viewForItem: (item) ->
    $$ ->
      stats = fs.statSync item
      @li class: 'two-lines', =>
        @div class: 'primary-line', path.basename(item)
        @div class: 'secondary-line', stats.ctime.toLocaleString()

  confirmed: (item) ->
    @hide()
    atom.particleDev.emitter.emit "#{packageName()}:flash-cloud",
      firmware: item
