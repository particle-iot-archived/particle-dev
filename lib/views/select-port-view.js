'use babel';

import { SelectView } from 'particle-dev-views';
import { packageName } from '../utils/package-helper';

let $$ = null;
let SerialHelper = null;

export default class SelectPortView extends SelectView {
	initialize(delegate) {
		super.initialize(...arguments);

		({ $$ } = require('atom-space-pen-views'));

		this.prop('id', 'select-port-view');
		this.addClass(packageName());
		this.listPortsPromise = null;
		this.delegate = delegate;
	}

	show() {
		this.setItems([]);
		this.setLoading('Listing ports...');
		this.listPorts();
		return super.show(...arguments);
	}

	viewForItem(item) {
		return $$(function render() {
			this.li({ class: 'two-lines' }, () => {
				this.div({ class: 'primary-line' }, item.serialNumber);
				this.div({ class: 'secondary-line' }, item.comName);
			});
		});
	}

	confirmed(item) {
		this.hide();
		// TODO: Cover it with tests
		return atom.particleDev.emitter.emit(this.delegate,
			{ port: item.comName });
	}

	getFilterKey() {
		return 'comName';
	}

	listPorts() {
		SerialHelper = require('../utils/serial-helper');
		this.listPortsPromise = SerialHelper.listPorts();
		return this.listPortsPromise.then(ports => {
			this.setItems(ports);
			this.listPortsPromise = null;
		}
			, e => console.error(e));
	}
}
