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
    $$ ->
      @li class: 'two-lines', =>
        @div class: 'primary-line', item.ssid
        @div class: 'secondary-line', item.security

  confirmed: (item) ->
    # TODO: Test this
    atom.workspaceView.trigger 'spark-ide:enter-wifi-credentials', [@port, item.value, item.security]
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
        #        SSID BSSID             RSSI CHANNEL HT CC SECURITY (auth/unicast/group)
        #               Plus MF60 BEB22B 2c:26:c5:be:b2:2b -74  11      N  PL WPA(PSK/AES,TKIP/TKIP) WPA2(PSK/AES,TKIP/TKIP)
        #                        Outline 64:7c:34:0c:ee:f9 -87  11      Y  PL WPA(PSK/AES,TKIP/TKIP) WPA2(PSK/AES,TKIP/TKIP)
        #                     UPC1818424 c4:27:95:85:3a:2f -51  11      Y  -- WPA(PSK/AES,TKIP/TKIP) WPA2(PSK/AES,TKIP/TKIP)
        #                    UPC Wi-Free c6:27:95:85:3a:21 -50  11      Y  -- WPA2(802.1x/AES,TKIP/TKIP)
        #                         future 00:18:39:d4:46:76 -82  11      N  -- WPA(PSK/AES,TKIP/TKIP) WPA2(PSK/AES,TKIP/TKIP)
        # HP-Print-E2-Officejet Pro 8600 2c:59:e5:f2:97:e2 -56  11      N  -- NONE
        #                     Konceptika d8:50:e6:5c:36:b8 -79  6       Y  -- WPA2(PSK/AES/AES)
        #                    UPC Wi-Free 8e:04:ff:f3:fe:20 -85  4       Y  -- WPA2(802.1x/AES,TKIP/TKIP)
        #                           suda 00:25:bc:8a:19:63 -43  5       Y  PL WPA(PSK/TKIP/TKIP) WPA2(PSK/AES,TKIP/TKIP)
        #                    UPC Wi-Free 8e:04:ff:f3:90:d8 -81  1       Y  -- WPA2(802.1x/AES,TKIP/TKIP)
        #                     UPC0802810 8c:04:ff:f3:90:d6 -84  1       Y  -- WPA(PSK/AES,TKIP/TKIP) WPA2(PSK/AES,TKIP/TKIP)
        #            Pentagram P 6331-42 00:04:ed:a3:7a:fc -82  1       N  -- WPA(PSK/TKIP/TKIP)
        #                   BRAK DOSTEPU e0:91:f5:75:21:f2 -60  1       Y  -- WPA2(PSK/AES/AES)
        #                     UPC3397002 64:7c:34:40:3f:2a -86  36,+1   Y  PL WPA(PSK/AES,TKIP/TKIP) WPA2(PSK/AES,TKIP/TKIP)
        #                           suda 00:25:bc:8a:19:64 -49  40,-1   Y  PL WPA(PSK/TKIP/TKIP) WPA2(PSK/AES,TKIP/TKIP)
        console.log stdout
