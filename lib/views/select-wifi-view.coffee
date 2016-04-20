{SelectView} = require 'particle-dev-views'
packageName = require '../utils/package-helper'

$$ = null
_s = null
WifiHelper = null

module.exports =
class SelectWifiView extends SelectView
  initialize: ->
    super

    {$$} = require 'atom-space-pen-views'
    @cp = require 'child_process'
    _s ?= require 'underscore.string'
    WifiHelper ?= require '../utils/wifi-helper'

    @prop 'id', 'select-wifi-view'
    @addClass packageName()
    @port = null

  show: =>
    @listNetworks()
    super

  viewForItem: (item) ->
    security = null

    switch item.security
      when 0
        security = 'Unsecured'
      when 1
        security = 'WEP'
      when 2
        security = 'WPA'
      when 3
        security = 'WPA2'

    $$ ->
      @li class: 'two-lines', =>
        if security
          @div class: 'pull-right', =>
            @kbd class: 'key-binding pull-right', security
        @div item.ssid

  confirmed: (item) ->
    @hide()
    if item.security
      atom.particleDev.emitter.emit "#{packageName()}:enter-wifi-credentials",
        port: @port
        ssid: item.ssid
        security: item.security
    else
      atom.particleDev.emitter.emit "#{packageName()}:enter-wifi-credentials",
        port: @port

  getPlatform: ->
    process.platform

  getFilterKey: ->
    'ssid'

  setNetworks: (networks) ->
    if networks.length > 0
      @setItems(networks.concat @items)
      @removeClass 'loading'
      @focusFilterEditor()
    else
      @setLoading()

  listNetworks: ->
    @addClass 'loading'
    @focusFilterEditor()
    @items = [{
      ssid: 'Enter SSID manually',
      security: null,
    }]
    @setItems @items
    @setLoading 'Scaning for networks...'

    WifiHelper.listNetworks().then (networks) =>
      @setNetworks networks
