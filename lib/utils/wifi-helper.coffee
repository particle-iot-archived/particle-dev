whenjs = require 'when'
pipeline = require 'when/pipeline'
utilities = require '../vendor/utilities.js'
_s = require 'underscore.string'

module.exports =
	cp: require 'child_process'

	getPlatform: ->
		process.platform

	getCurrentSsid: ->
		dfd = whenjs.defer()
		switch @getPlatform()
			when 'darwin'
				@getCurrentSsidDarwin (currentNetwork) ->
					dfd.resolve currentNetwork
			when 'win32'
				@getCurrentSsidWindows (currentNetwork) ->
					dfd.resolve currentNetwork
			else
				dfd.reject 'Current platform is not supported'
		dfd.promise

	getCurrentSsidDarwin: (cb) ->
		@cp.exec '/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I', (error, stdout, stderr) =>
			currentSsid = null
			if stdout != ''
				currentSsid = stdout.match /\sSSID\:\s(.*)/
				if !!currentSsid
					currentSsid = currentSsid[1]
			cb currentSsid

	getCurrentSsidWindows: (cb) ->
		@cp.exec 'netsh wlan show interfaces', (error, stdout, stderr) =>
			currentSsid = null
			if stdout != ''
				currentSsid = stdout.match /\sSSID\s+\:\s(.*)/
				if !!currentSsid
					currentSsid = currentSsid[1]
			cb currentSsid

	sortNetworks: (networks, currentFirst) ->
		# TODO: Current first
		networks.sort (a, b) =>
			if currentFirst
				if a.ssid == currentSsid
					return -1000
				if b.ssid == currentSsid
					return 1000

			parseInt(b.rssi) - parseInt(a.rssi)
		return networks

	listNetworks: (currentFirst=true) ->
		dfd = whenjs.defer()
		switch @getPlatform()
			when 'darwin'
				@listNetworksDarwin (networks) =>
					dfd.resolve @sortNetworks(networks, currentFirst)
			when 'win32'
				@listNetworksWindows (networks) =>
					dfd.resolve @sortNetworks(networks, currentFirst)
			else
				dfd.reject 'Current platform is not supported'
		dfd.promise

	listNetworksDarwin: (cb) ->
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

			cb networks

	listNetworksWindows: (cb) ->
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

			cb networks
