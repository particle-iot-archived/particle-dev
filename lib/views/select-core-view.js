'use babel';

import { SelectView } from 'particle-dev-views';
import { packageName } from '../utils/package-helper';

let $$ = null;

export default class SelectCoreView extends SelectView {
	initialize() {
		super.initialize(...arguments);

		({ $$ } = require('atom-space-pen-views'));

		this.prop('id', 'select-core-view');
		this.addClass(packageName());
		this.listDevicesPromise = null;
		this.main = null;
		this.requestErrorHandler = null;
	}

	show(next=null) {
		this.setItems([]);
		this.next = next;
		this.setLoading('Loading devices...');
		this.loadCores();
		super.show(...arguments);
	}

	// Here you specify the view for an item
	viewForItem(item) {
		let { name } = item;
		if (!name) {
			name = 'Unnamed';
		}

		return $$(function render() {
			this.li({ class: 'two-lines core-line' }, () => {
				const connectedClass = item.connected ? 'core-online' : 'core-offline';
				this.div({ class: `primary-line ${connectedClass}` }, () => {
					this.span({ class: `platform-icon platform-icon-${item.platform_id}` }, name);
				});
				this.div({ class: 'secondary-line no-icon' }, item.id);
			});
		});
	}

	confirmed(item) {
		const device = this.main.profileManager.Device.fromApiV1(item);
		this.main.profileManager.currentDevice = device;

		if (typeof item.platform_id !== 'undefined') {
			this.main.profileManager.currentTargetPlatform = item.platform_id;
			if ((item.platform_id === 10) && item.current_build_target) {
				this.main.setCurrentBuildTarget(item.current_build_target);
			}
		}
		this.hide();
		atom.commands.dispatch(this.workspaceElement, `${packageName()}:update-core-status`);
		atom.commands.dispatch(this.workspaceElement, `${packageName()}:update-menu`);
		if (this.next) {
			return this.next(item);
		}
	}

	getFilterKey() {
		return 'name';
	}

	loadCores() {
		this.listDevicesPromise = this.main.profileManager.apiClient.listDevices();
		return this.listDevicesPromise.then(value => {
			const e = value.body;
			e.sort((a, b) => {
				if (!a.name) {
					a.name = 'Unnamed';
				}
				if (!b.name) {
					b.name = 'Unnamed';
				}
				let order = (b.connected - a.connected) * 1000;
				if (a.name.toLowerCase() < b.name.toLowerCase()) {
					order -= 1;
				} else if (a.name.toLowerCase() > b.name.toLowerCase()) {
					order += 1;
				}
				return order;
			});

			this.setItems(e);
			this.listDevicesPromise = null;
		}
			, e => {
			// TODO: Error handling
			this.listDevicesPromise = null;
			return this.requestErrorHandler(e);
		});
	}
}
