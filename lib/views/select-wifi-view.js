'use babel';

import { SelectView } from 'particle-dev-views';
import { packageName } from '../utils/package-helper';

let $$ = null;
let WifiHelper = null;

export default class SelectWifiView extends SelectView {
	initialize() {
		super.initialize(...arguments);

		({ $$ } = require('atom-space-pen-views'));
		this.cp = require('child_process');
		if (WifiHelper == null) {
			WifiHelper = require('../utils/wifi-helper');
		}

		this.prop('id', 'select-wifi-view');
		this.addClass(packageName());
		this.port = null;
	}

	show() {
		this.listNetworks();
		return super.show(...arguments);
	}

	viewForItem(item) {
		let security = null;

		switch (item.security) {
			case 0:
				security = 'Unsecured';
				break;
			case 1:
				security = 'WEP';
				break;
			case 2:
				security = 'WPA';
				break;
			case 3:
				security = 'WPA2';
				break;
		}

		return $$(function render() {
			this.li({ class: 'two-lines' }, () => {
				if (security) {
					this.div({ class: 'pull-right' }, () => {
						this.kbd({ class: 'key-binding pull-right' }, security);
					});
				}
				this.div(item.ssid);
			});
		});
	}

	confirmed(item) {
		this.hide();
		if (item.security) {
			return atom.particleDev.emitter.emit(`${packageName()}:enter-wifi-credentials`, {
				port: this.port,
				ssid: item.ssid,
				security: item.security
			}
			);
		} else {
			return atom.particleDev.emitter.emit(`${packageName()}:enter-wifi-credentials`,
				{ port: this.port });
		}
	}

	getPlatform() {
		return process.platform;
	}

	getFilterKey() {
		return 'ssid';
	}

	setNetworks(networks) {
		if (networks.length > 0) {
			this.setItems(networks.concat(this.items));
			this.removeClass('loading');
			this.focusFilterEditor();
		} else {
			this.setLoading();
		}
	}

	listNetworks() {
		this.addClass('loading');
		this.focusFilterEditor();
		this.items = [{
			ssid: 'Enter SSID manually',
			security: null,
		}];
		this.setItems(this.items);
		this.setLoading('Scaning for networks...');

		return WifiHelper.listNetworks().then(networks => {
			this.setNetworks(networks);
		});
	}
}
