SelectListView = require('atom').SelectListView

$ = null
$$ = null
Subscriber = null
cp = null

module.exports =
class SelectWifiView extends SelectListView
  initialize: ->
    super

    {$, $$} = require 'atom'
    {Subscriber} = require 'emissary'

    cp ?= require 'child_process'

    @subscriber = new Subscriber()
    @subscriber.subscribeToCommand atom.workspaceView, 'core:cancel core:close', => @hide()

    @addClass 'overlay from-top'
    @prop 'id', 'spark-ide-select-wifi-view'
    @listPortsPromise = null

  destroy: ->
    @remove()

  show: =>
    if !@hasParent()
      atom.workspaceView.append(this)

      @setItems []
      @setLoading 'Scaning for networks...'
      @listNetworks()
      @focusFilterEditor()

  hide: ->
    if @hasParent()
      @detach()

  viewForItem: (item) ->
    $$ ->
      @li class: 'two-lines', =>
        @div class: 'primary-line', item.ssid
        @div class: 'secondary-line', item.security

  confirmed: (item) ->
    # TODO: Test this
    atom.workspaceView.trigger 'spark-ide:', [item.value]
    @cancel()

  getFilterKey: ->
    'comName'

  listNetworks: ->
    items = [{
      ssid: 'Enter SSID manually',
      security: '',
      value: ''
    }]
    @setItems items

    # TODO: Implement
    cp.exec '/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I', (error, stdout, stderr) =>
      ssid = null
      if stdout != ''
        # TODO: Get current WiFi
        #     agrCtlRSSI: -59
        #     agrExtRSSI: 0
        #    agrCtlNoise: -92
        #    agrExtNoise: 0
        #          state: running
        #        op mode: station
        #     lastTxRate: 585
        #        maxRate: 1300
        # lastAssocStatus: 0
        #    802.11 auth: open
        #      link auth: wpa2-psk
        #          BSSID: c8:d7:19:39:a6:75
        #           SSID: ISSUESTAND
        #            MCS: 7
        #        channel: 36,80
        console.log stdout

      cp.exec '/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s', (error, stdout, stderr) =>
        # TODO: Parse networks list
        console.log stdout
