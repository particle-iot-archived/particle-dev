SelectListView = require('atom').SelectListView

$ = null
$$ = null
Subscriber = null
cp = null
_s = null

module.exports =
class SelectWifiView extends SelectListView
  initialize: ->
    super

    {$, $$} = require 'atom'
    {Subscriber} = require 'emissary'

    cp ?= require 'child_process'
    _s ?= require 'underscore.string'

    @subscriber = new Subscriber()
    @subscriber.subscribeToCommand atom.workspaceView, 'core:cancel core:close', => @hide()

    @addClass 'overlay from-top'
    @prop 'id', 'spark-ide-select-wifi-view'

    @port = null

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
        if !!security
          @div class: 'pull-right', =>
            @kbd class: 'key-binding pull-right', security
        @div item.ssid

  confirmed: (item) ->
    # TODO: Test this
    atom.workspaceView.trigger 'spark-ide:enter-wifi-credentials', [@port, item.ssid, item.security]
    @cancel()

  listNetworks: ->
    switch process.platform
      when 'darwin'
        @listNetworksDarwin()
      else
        console.error 'Current platform not supported'

        @setItems [{
          ssid: 'Enter SSID manually',
          security: null,
        }]

  listNetworksDarwin: ->
    cp.exec '/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I', (error, stdout, stderr) =>
      ssid = null
      if stdout != ''
        ssid = stdout.match /\sSSID\:\s(.*)/
        if !!ssid
          ssid = ssid[1]

      cp.exec '/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s', (error, stdout, stderr) =>
        regex = /\s+(.*)\s+([0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2})\s+([0-9\-]+)\s+([0-9\,\-\+]+)\s+([YN]+)\s+([A-Z\-]+)\s+(.*)\s/

        networks = []
        for line in stdout.split "\n"
          network = regex.exec line

          if !!network
            notAdded = (networks.length == 0) || networks.reduce (prev, current) ->
              prev && (current.ssid != network[1])

            if notAdded
              if network[7].indexOf 'WPA2' > -1
                security = 3
              else if network[7].indexOf 'WPA(' > -1
                security = 2
              else if network[7].indexOf 'WEP' > -1
                security = 1
              else
                security = 0

              networks.push {
                ssid: network[1],
                bssid: network[2],
                rssi: network[3],
                channel: network[4],
                ht: network[5],
                cc: network[6],
                security_string: network[7],
                security: security
              }

        networks.sort (a, b) ->
          if a.ssid == ssid
            return -1000
          if b.ssid == ssid
            return 1000

          parseInt(b.rssi) - parseInt(a.rssi)

        networks.push {
          ssid: 'Enter SSID manually',
          security: null,
        }

        @setItems networks
