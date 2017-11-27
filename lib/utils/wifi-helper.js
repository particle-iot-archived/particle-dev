'use babel';

import whenjs from 'when';
import pipeline from 'when/pipeline';
import _s from 'underscore.string';

export default {
	cp: require('child_process'),

	getPlatform() {
		return process.platform;
	},

	getCurrentSsid() {
		const dfd = whenjs.defer();
		switch (this.getPlatform()) {
			case 'darwin':
				this.getCurrentSsidDarwin(currentNetwork => dfd.resolve(currentNetwork));
				break;
			case 'win32':
				this.getCurrentSsidWindows(currentNetwork => dfd.resolve(currentNetwork));
				break;
			default:
				dfd.reject('Current platform is not supported');
		}
		return dfd.promise;
	},

	getCurrentSsidDarwin(cb) {
		return this.cp.exec('/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I', function(error, stdout, stderr) {
			let currentSsid = null;
			if (stdout !== '') {
				currentSsid = stdout.match(/\sSSID\:\s(.*)/);
				if (currentSsid) {
					currentSsid = currentSsid[1];
				}
			}
			return cb(currentSsid);
		});
	},

	getCurrentSsidWindows(cb) {
		return this.cp.exec('netsh wlan show interfaces', function(error, stdout, stderr) {
			let currentSsid = null;
			if (stdout !== '') {
				currentSsid = stdout.match(/\sSSID\s+\:\s(.*)/);
				if (currentSsid) {
					currentSsid = currentSsid[1];
				}
			}
			return cb(currentSsid);
		});
	},

	sortNetworks(networks, currentSsid) {
		networks.sort(function(a, b) {
			if (currentSsid) {
				if (a.ssid === currentSsid) {
					return -1000;
				}
				if (b.ssid === currentSsid) {
					return 1000;
				}
			}

			return parseInt(b.rssi) - parseInt(a.rssi);
		});
		return networks;
	},

	listNetworksDfd(currentSsid=null) {
		const dfd = whenjs.defer();

		switch (this.getPlatform()) {
			case 'darwin':
				this.listNetworksDarwin(networks => {
					return dfd.resolve(this.sortNetworks(networks, currentSsid));
				});
				break;
			case 'win32':
				this.listNetworksWindows(networks => {
					return dfd.resolve(this.sortNetworks(networks, currentSsid));
				});
				break;
			default:
				dfd.reject('Current platform is not supported');
		}
		return dfd.promise;
	},

	listNetworks(currentFirst) {
		if (currentFirst == null) {
			currentFirst = true;
		}
		if (currentFirst) {
			return pipeline([
				() => {
					return this.getCurrentSsid();
				},
				currentSsid => {
					return this.listNetworksDfd(currentSsid);
				}
			]);
		} else {
			return this.listNetworksDfd();
		}
	},

	listNetworksDarwin(cb) {
		return this.cp.exec('/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s', function(error, stdout, stderr) {
			const regex = /(.*)\s+([0-9a-f\:]{17})\s+([0-9\-]+)\s+([0-9\,\-\+]+)\s+([YN]+)\s+([A-Z\-]+)\s+(.*)/;

			const networks = [];
			for (let line of stdout.split('\n')) {
				var network = regex.exec(line);

				if (network) {
					const notAdded = (networks.length === 0) || networks.reduce((prev, current) => prev && (current.ssid !== _s.trim(network[1])));

					if (notAdded) {
						var security;
						if (network[7].indexOf('WPA2') > -1) {
							security = 3;
						} else if (network[7].indexOf('WPA(') > -1) {
							security = 2;
						} else if (network[7].indexOf('WEP') > -1) {
							security = 1;
						} else {
							security = 0;
						}

						networks.push({
							ssid: _s.trim(network[1]),
							bssid: network[2],
							rssi: network[3],
							channel: network[4],
							ht: network[5],
							cc: network[6],
							security_string: network[7],
							security
						});
					}
				}
			}

			return cb(networks);
		});
	},

	listNetworksWindows(cb) {
		return this.cp.exec('netsh wlan show networks mode=bssid', function(error, stdout, stderr) {
			const ssidRegex = /SSID [0-9]+ \: (.*)/;
			const authenticationRegex = /Authentication\s+\: (.*)/;
			const encryptionRegex = /Encryption\s+\: (.*)/;
			const bssidRegex = /BSSID [0-9]+\s+\: (.*)/;
			const rssiRegex = /Signal\s+\: ([0-9]+)/;
			const channelRegex = /Channel\s+\: ([0-9]+)/;
			const networks = [];
			for (let line of stdout.split('\r\n\r\n')) {
				let ssid = ssidRegex.exec(line);
				if (!!ssid && (ssid[1] !== '')) {
					var security;
					ssid = ssid[1];
					const authentications = authenticationRegex.exec(line);
					const authentication = authentications[1];
					const encryptions = encryptionRegex.exec(line);
					const encryption = encryptions[1];
					const bssids = bssidRegex.exec(line);
					const rssis = rssiRegex.exec(line);
					const channels = channelRegex.exec(line);

					if (authentication.indexOf('WPA2') > -1) {
						security = 3;
					} else if (authentication.indexOf('WPA') > -1) {
						security = 2;
					} else if (encryption.indexOf('WEP') > -1) {
						security = 1;
					} else {
						security = 0;
					}

					networks.push({
						ssid,
						bssid: bssids[1],
						rssi: rssis[1],
						channel: channels[1],
						authentication,
						encryption,
						security
					});
				}
			}

			return cb(networks);
		});
	}
};
