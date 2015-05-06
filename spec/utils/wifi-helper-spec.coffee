whenjs = require 'when'

describe 'getting current SSID when', ->
	WifiHelper = null

	beforeEach ->
		WifiHelper = require '../../lib/utils/wifi-helper'
		delete require.cache[require.resolve('../../lib/utils/wifi-helper')]

	it 'detects OS', (done) ->
		WifiHelper.getPlatform = -> 'darwin'
		WifiHelper.getCurrentSsidDarwin = jasmine.createSpy().andCallFake (cb) ->
			cb 'foo'

		promise = WifiHelper.getCurrentSsid()

		waitsFor ->
			promise.inspect().state == 'fulfilled'

		runs ->
			status = promise.inspect()
			expect(status.value).toEqual('foo')
			expect(WifiHelper.getCurrentSsidDarwin).toHaveBeenCalled()

			WifiHelper.getPlatform = -> 'win32'
			WifiHelper.getCurrentSsidWindows = jasmine.createSpy().andCallFake (cb) ->
				cb 'bar'
			promise = WifiHelper.getCurrentSsid()

		waitsFor ->
			promise.inspect().state == 'fulfilled'

		runs ->
			status = promise.inspect()
			expect(status.value).toEqual('bar')
			expect(WifiHelper.getCurrentSsidWindows).toHaveBeenCalled()

	it 'runs on Darwin', (done) ->
		stdout = fs.readFileSync __dirname + '/../data/interfaces-darwin.txt'

		WifiHelper.cp =
			exec: jasmine.createSpy().andCallFake (cmd, cb) ->
				cb null, stdout.toString(), null

		ssid = null
		WifiHelper.getCurrentSsidDarwin (_ssid) ->
			ssid = _ssid

		waitsFor ->
			!!ssid

		runs ->
			expect(WifiHelper.cp.exec).toHaveBeenCalled()
			expect(WifiHelper.cp.exec.calls[0].args[0]).toEqual('/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I')
			expect(ssid).toEqual('foo')

	it 'runs on Windows', (done) ->
		stdout = fs.readFileSync __dirname + '/../data/interfaces-win.txt'

		WifiHelper.cp =
			exec: jasmine.createSpy().andCallFake (cmd, cb) ->
				cb null, stdout.toString(), null

		ssid = null
		WifiHelper.getCurrentSsidWindows (_ssid) ->
			ssid = _ssid

		waitsFor ->
			!!ssid

		runs ->
			expect(WifiHelper.cp.exec).toHaveBeenCalled()
			expect(WifiHelper.cp.exec.calls[0].args[0]).toEqual('netsh wlan show interfaces')
			expect(ssid).toEqual('foo')

describe 'listing available networks when', ->
	WifiHelper = null

	beforeEach ->
		WifiHelper = require '../../lib/utils/wifi-helper'
		delete require.cache[require.resolve('../../lib/utils/wifi-helper')]

	it 'detects OS', (done) ->
		args = [
			ssid: 'foo'
			rssi: 0
		]
		WifiHelper.getPlatform = -> 'darwin'
		WifiHelper.listNetworksDarwin = jasmine.createSpy().andCallFake (cb) ->
			cb args
		promise = WifiHelper.listNetworks()

		waitsFor ->
			promise.inspect().state == 'fulfilled'

		runs ->
			status = promise.inspect()
			expect(status.value).toEqual(args)
			expect(WifiHelper.listNetworksDarwin).toHaveBeenCalled()

			WifiHelper.getPlatform = -> 'win32'
			WifiHelper.listNetworksWindows = jasmine.createSpy().andCallFake (cb) ->
				cb args
			promise = WifiHelper.listNetworks()

		waitsFor ->
			promise.inspect().state == 'fulfilled'

		runs ->
			status = promise.inspect()
			expect(status.value).toEqual(args)
			expect(WifiHelper.listNetworksWindows).toHaveBeenCalled()

	it 'runs on Darwin', (done) ->
		stdout = fs.readFileSync __dirname + '/../data/networks-darwin.txt'

		WifiHelper.cp =
			exec: jasmine.createSpy().andCallFake (cmd, cb) ->
				cb null, stdout.toString(), null

		networks = null
		WifiHelper.listNetworksDarwin (_networks) ->
			networks = _networks

		waitsFor ->
			!!networks

		runs ->
			expect(WifiHelper.cp.exec).toHaveBeenCalled()
			expect(WifiHelper.cp.exec.calls[0].args[0]).toEqual('/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s')
			expect(networks.length).toEqual(13)
			expect(networks[1].ssid).toEqual('foo')
			expect(networks[1].bssid).toEqual('00:25:ac:8a:19:6a')
			expect(networks[1].rssi).toEqual('-60')
			expect(networks[1].channel).toEqual('5')
			expect(networks[1].ht).toEqual('Y')
			expect(networks[1].cc).toEqual('PL')
			expect(networks[1].security_string).toEqual('WPA(PSK/TKIP/TKIP) WPA2(PSK/AES,TKIP/TKIP)')
			expect(networks[1].security).toEqual(3)

			expect(networks[9].security).toEqual(0)
			expect(networks[2].security).toEqual(2)
			expect(networks[8].security).toEqual(1)

	it 'runs on Windows', (done) ->
		stdout = fs.readFileSync __dirname + '/../data/networks-win.txt'

		WifiHelper.cp =
			exec: jasmine.createSpy().andCallFake (cmd, cb) ->
				cb null, stdout.toString(), null

		networks = null
		WifiHelper.listNetworksWindows (_networks) ->
			networks = _networks

		waitsFor ->
			!!networks

		runs ->
			expect(WifiHelper.cp.exec).toHaveBeenCalled()
			expect(WifiHelper.cp.exec.calls[0].args[0]).toEqual('netsh wlan show networks mode=bssid')
			expect(networks.length).toEqual(5)
			expect(networks[3].ssid).toEqual('foo')
			expect(networks[3].bssid).toEqual('c8:d7:19:39:a6:74')
			expect(networks[3].rssi).toEqual('96')
			expect(networks[3].channel).toEqual('3')
			expect(networks[3].authentication).toEqual('WPA2-Personal')
			expect(networks[3].encryption).toEqual('CCMP')
			expect(networks[3].security).toEqual(3)

			expect(networks[0].security).toEqual(2)
			expect(networks[1].security).toEqual(3)
			expect(networks[2].security).toEqual(0)
			expect(networks[4].security).toEqual(1)

describe 'sorts networks when', ->
	WifiHelper = null

	beforeEach ->
		WifiHelper = require '../../lib/utils/wifi-helper'
		delete require.cache[require.resolve('../../lib/utils/wifi-helper')]

	it 'they have to be ordered by signal strength', ->
		stdout = fs.readFileSync __dirname + '/../data/networks-darwin.txt'
		WifiHelper.getPlatform = -> 'darwin'
		WifiHelper.cp =
			exec: jasmine.createSpy().andCallFake (cmd, cb) ->
				cb null, stdout.toString(), null

		promise = WifiHelper.listNetworks false

		waitsFor ->
			promise.inspect().state == 'fulfilled'

		runs ->
			status = promise.inspect()
			networks = status.value
			expect(networks[0].ssid).toEqual('BTWifi-with-FON')
			expect(networks[1].ssid).toEqual('BTHub3-P98X')
			expect(networks[2].ssid).toEqual('EE-BrightBox-qwa4e4')

	it 'wants current SSID to be first', ->
		stdout = fs.readFileSync __dirname + '/../data/networks-darwin.txt'
		WifiHelper.getPlatform = -> 'darwin'
		WifiHelper.cp =
			exec: jasmine.createSpy().andCallFake (cmd, cb) ->
				cb null, stdout.toString(), null
		WifiHelper.getCurrentSsid = jasmine.createSpy().andCallFake ->
			whenjs.resolve 'foo'

		promise = WifiHelper.listNetworks true

		waitsFor ->
			promise.inspect().state == 'fulfilled'

		runs ->
			status = promise.inspect()
			networks = status.value
			expect(networks[0].ssid).toEqual('foo')
			expect(networks[1].ssid).toEqual('BTWifi-with-FON')
			expect(networks[2].ssid).toEqual('BTHub3-P98X')
