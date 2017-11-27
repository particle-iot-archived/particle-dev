'use babel';
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import whenjs from 'when';
import fs from 'fs-plus';

describe('getting current SSID when', function() {
	let WifiHelper = null;

	beforeEach(function() {
		WifiHelper = require('../../lib/utils/wifi-helper');
		return delete require.cache[require.resolve('../../lib/utils/wifi-helper')];});

	it('detects OS', function(done) {
		WifiHelper.getPlatform = () => 'darwin';
		WifiHelper.getCurrentSsidDarwin = jasmine.createSpy().andCallFake(cb => cb('foo'));

		let promise = WifiHelper.getCurrentSsid();

		waitsFor(() => promise.inspect().state === 'fulfilled');

		runs(function() {
			const status = promise.inspect();
			expect(status.value).toEqual('foo');
			expect(WifiHelper.getCurrentSsidDarwin).toHaveBeenCalled();

			WifiHelper.getPlatform = () => 'win32';
			WifiHelper.getCurrentSsidWindows = jasmine.createSpy().andCallFake(cb => cb('bar'));
			return promise = WifiHelper.getCurrentSsid();
		});

		waitsFor(() => promise.inspect().state === 'fulfilled');

		return runs(function() {
			const status = promise.inspect();
			expect(status.value).toEqual('bar');
			return expect(WifiHelper.getCurrentSsidWindows).toHaveBeenCalled();
		});
	});

	it('runs on Darwin', function(done) {
		const stdout = fs.readFileSync(__dirname + '/../data/interfaces-darwin.txt');

		WifiHelper.cp = {
			exec: jasmine.createSpy().andCallFake((cmd, cb) => cb(null, stdout.toString(), null))
		};

		let ssid = null;
		WifiHelper.getCurrentSsidDarwin(_ssid => ssid = _ssid);

		waitsFor(() => !!ssid);

		return runs(function() {
			expect(WifiHelper.cp.exec).toHaveBeenCalled();
			expect(WifiHelper.cp.exec.calls[0].args[0]).toEqual('/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I');
			return expect(ssid).toEqual('foo');
		});
	});

	return it('runs on Windows', function(done) {
		const stdout = fs.readFileSync(__dirname + '/../data/interfaces-win.txt');

		WifiHelper.cp = {
			exec: jasmine.createSpy().andCallFake((cmd, cb) => cb(null, stdout.toString(), null))
		};

		let ssid = null;
		WifiHelper.getCurrentSsidWindows(_ssid => ssid = _ssid);

		waitsFor(() => !!ssid);

		return runs(function() {
			expect(WifiHelper.cp.exec).toHaveBeenCalled();
			expect(WifiHelper.cp.exec.calls[0].args[0]).toEqual('netsh wlan show interfaces');
			return expect(ssid).toEqual('foo');
		});
	});
});

describe('listing available networks when', function() {
	let WifiHelper = null;

	beforeEach(function() {
		WifiHelper = require('../../lib/utils/wifi-helper');
		return delete require.cache[require.resolve('../../lib/utils/wifi-helper')];});

	it('detects OS', function(done) {
		const args = [{
			ssid: 'foo',
			rssi: 0
		}
		];
		WifiHelper.getPlatform = () => 'darwin';
		WifiHelper.listNetworksDarwin = jasmine.createSpy().andCallFake(cb => cb(args));
		let promise = WifiHelper.listNetworks();

		waitsFor(() => promise.inspect().state === 'fulfilled');

		runs(function() {
			const status = promise.inspect();
			expect(status.value).toEqual(args);
			expect(WifiHelper.listNetworksDarwin).toHaveBeenCalled();

			WifiHelper.getPlatform = () => 'win32';
			WifiHelper.listNetworksWindows = jasmine.createSpy().andCallFake(cb => cb(args));
			return promise = WifiHelper.listNetworks();
		});

		waitsFor(() => promise.inspect().state === 'fulfilled');

		return runs(function() {
			const status = promise.inspect();
			expect(status.value).toEqual(args);
			return expect(WifiHelper.listNetworksWindows).toHaveBeenCalled();
		});
	});

	it('runs on Darwin', function(done) {
		const stdout = fs.readFileSync(__dirname + '/../data/networks-darwin.txt');

		WifiHelper.cp = {
			exec: jasmine.createSpy().andCallFake((cmd, cb) => cb(null, stdout.toString(), null))
		};

		let networks = null;
		WifiHelper.listNetworksDarwin(_networks => networks = _networks);

		waitsFor(() => !!networks);

		return runs(function() {
			expect(WifiHelper.cp.exec).toHaveBeenCalled();
			expect(WifiHelper.cp.exec.calls[0].args[0]).toEqual('/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s');
			expect(networks.length).toEqual(13);
			expect(networks[1].ssid).toEqual('foo');
			expect(networks[1].bssid).toEqual('00:25:ac:8a:19:6a');
			expect(networks[1].rssi).toEqual('-60');
			expect(networks[1].channel).toEqual('5');
			expect(networks[1].ht).toEqual('Y');
			expect(networks[1].cc).toEqual('PL');
			expect(networks[1].security_string).toEqual('WPA(PSK/TKIP/TKIP) WPA2(PSK/AES,TKIP/TKIP)');
			expect(networks[1].security).toEqual(3);

			expect(networks[9].security).toEqual(0);
			expect(networks[2].security).toEqual(2);
			return expect(networks[8].security).toEqual(1);
		});
	});

	return it('runs on Windows', function(done) {
		const stdout = fs.readFileSync(__dirname + '/../data/networks-win.txt');

		WifiHelper.cp = {
			exec: jasmine.createSpy().andCallFake((cmd, cb) => cb(null, stdout.toString(), null))
		};

		let networks = null;
		WifiHelper.listNetworksWindows(_networks => networks = _networks);

		waitsFor(() => !!networks);

		return runs(function() {
			expect(WifiHelper.cp.exec).toHaveBeenCalled();
			expect(WifiHelper.cp.exec.calls[0].args[0]).toEqual('netsh wlan show networks mode=bssid');
			expect(networks.length).toEqual(5);
			expect(networks[3].ssid).toEqual('foo');
			expect(networks[3].bssid).toEqual('c8:d7:19:39:a6:74');
			expect(networks[3].rssi).toEqual('96');
			expect(networks[3].channel).toEqual('3');
			expect(networks[3].authentication).toEqual('WPA2-Personal');
			expect(networks[3].encryption).toEqual('CCMP');
			expect(networks[3].security).toEqual(3);

			expect(networks[0].security).toEqual(2);
			expect(networks[1].security).toEqual(3);
			expect(networks[2].security).toEqual(0);
			return expect(networks[4].security).toEqual(1);
		});
	});
});

describe('sorts networks when', function() {
	let WifiHelper = null;

	beforeEach(function() {
		WifiHelper = require('../../lib/utils/wifi-helper');
		return delete require.cache[require.resolve('../../lib/utils/wifi-helper')];});

	it('they have to be ordered by signal strength', function() {
		const stdout = fs.readFileSync(__dirname + '/../data/networks-darwin.txt');
		WifiHelper.getPlatform = () => 'darwin';
		WifiHelper.cp = {
			exec: jasmine.createSpy().andCallFake((cmd, cb) => cb(null, stdout.toString(), null))
		};

		const promise = WifiHelper.listNetworks(false);

		waitsFor(() => promise.inspect().state === 'fulfilled');

		return runs(function() {
			const status = promise.inspect();
			const networks = status.value;
			expect(networks[0].ssid).toEqual('BTWifi-with-FON');
			expect(networks[1].ssid).toEqual('BTHub3-P98X');
			return expect(networks[2].ssid).toEqual('EE-BrightBox-qwa4e4');
		});
	});

	return it('wants current SSID to be first', function() {
		const stdout = fs.readFileSync(__dirname + '/../data/networks-darwin.txt');
		WifiHelper.getPlatform = () => 'darwin';
		WifiHelper.cp = {
			exec: jasmine.createSpy().andCallFake((cmd, cb) => cb(null, stdout.toString(), null))
		};
		WifiHelper.getCurrentSsid = jasmine.createSpy().andCallFake(() => whenjs.resolve('foo'));

		const promise = WifiHelper.listNetworks(true);

		waitsFor(() => promise.inspect().state === 'fulfilled');

		return runs(function() {
			const status = promise.inspect();
			const networks = status.value;
			expect(networks[0].ssid).toEqual('foo');
			expect(networks[1].ssid).toEqual('BTWifi-with-FON');
			return expect(networks[2].ssid).toEqual('BTHub3-P98X');
		});
	});
});
