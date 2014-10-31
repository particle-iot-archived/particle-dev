SelectListView = require('atom').SelectListView

$ = null
$$ = null
Subscriber = null
_s = null

module.exports =
class SelectWifiView extends SelectListView
  initialize: ->
    super

    {$, $$} = require 'atom'
    {Subscriber} = require 'emissary'

    @cp = require 'child_process'
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

      @listNetworks()

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
        if security
          @div class: 'pull-right', =>
            @kbd class: 'key-binding pull-right', security
        @div item.ssid

  confirmed: (item) ->
    @cancel()

    if item.security
      atom.workspaceView.trigger 'spark-ide:enter-wifi-credentials', [@port, item.ssid, item.security]
    else
      atom.workspaceView.trigger 'spark-ide:enter-wifi-credentials', [@port]

  getPlatform: ->
    process.platform

  getFilterKey: ->
    'ssid'

  listNetworks: ->
    @filterEditorView.hide()

    @items = [{
      ssid: 'Enter SSID manually',
      security: null,
    }]
    @setItems @items
    @setLoading 'Scaning for networks...'

    switch @getPlatform()
      when 'darwin'
        @listNetworksDarwin()
      when 'win32'
        @listNetworksWindows()
      else
        console.error 'Current platform not supported'

  listNetworksDarwin: ->
    @cp.exec '/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I', (error, stdout, stderr) =>
      currentSsid = null
      if stdout != ''
        currentSsid = stdout.match /\sSSID\:\s(.*)/
        if !!currentSsid
          currentSsid = currentSsid[1]

      @cp.exec '/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s', (error, stdout, stderr) =>
        regex = /(.*)\s+([0-9a-f\:]{17})\s+([0-9\-]+)\s+([0-9\,\-\+]+)\s+([YN]+)\s+([A-Z\-]+)\s+(.*)/

        networks = []
        for line in stdout.split "\n"
          network = regex.exec line

          if !!network
            notAdded = (networks.length == 0) || networks.reduce (prev, current) ->
              prev && (current.ssid != _s.trim(network[1]))

            if notAdded
              if network[7].indexOf('WPA2') > -1
                security = 3
              else if network[7].indexOf('WPA(') > -1
                security = 2
              else if network[7].indexOf('WEP') > -1
                security = 1
              else
                security = 0

              networks.push {
                ssid: _s.trim(network[1]),
                bssid: network[2],
                rssi: network[3],
                channel: network[4],
                ht: network[5],
                cc: network[6],
                security_string: network[7],
                security: security
              }

        networks.sort (a, b) ->
          if a.ssid == currentSsid
            return -1000
          if b.ssid == currentSsid
            return 1000

          parseInt(b.rssi) - parseInt(a.rssi)

        @setItems(networks.concat @items)
        @filterEditorView.show()
        @focusFilterEditor()

  listNetworksWindows: ->
    fs = require 'fs-plus'
    @cp.exec 'netsh wlan show interfaces', (error, stdout, stderr) =>
      currentSsid = null
      if stdout != ''
        currentSsid = stdout.match /\sSSID\s+\:\s(.*)/
        if !!currentSsid
          currentSsid = currentSsid[1]

      @cp.exec 'netsh wlan show networks mode=bssid', (error, stdout, stderr) =>
        ssidRegex = /SSID [0-9]+ \: (.*)/
        authenticationRegex = /Authentication\s+\: (.*)/
        encryptionRegex = /Encryption\s+\: (.*)/
        bssidRegex = /BSSID [0-9]+\s+\: (.*)/
        rssiRegex = /Signal\s+\: ([0-9]+)/
        channelRegex = /Channel\s+\: ([0-9]+)/
        networks = []
        for line in stdout.split "\r\n\r\n"
          ssid = ssidRegex.exec line
          if !!ssid && ssid[1] != ''
            ssid = ssid[1]
            authentications = authenticationRegex.exec line
            authentication = authentications[1]
            encryptions = encryptionRegex.exec line
            encryption = encryptions[1]
            bssids = bssidRegex.exec line
            rssis = rssiRegex.exec line
            channels = channelRegex.exec line

            if authentication.indexOf('WPA2') > -1
              security = 3
            else if authentication.indexOf('WPA') > -1
              security = 2
            else if encryption.indexOf('WEP') > -1
              security = 1
            else
              security = 0

            networks.push {
              ssid: ssid,
              bssid: bssids[1],
              rssi: rssis[1],
              channel: channels[1],
              authentication: authentication,
              encryption: encryption,
              security: security
            }

        networks.sort (a, b) ->
          if a.ssid == currentSsid
            return -1000
          if b.ssid == currentSsid
            return 1000

          parseInt(b.rssi) - parseInt(a.rssi)

        @setItems(networks.concat @items)
        @filterEditorView.show()
        @focusFilterEditor()
