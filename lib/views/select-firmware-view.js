'use babel';

import { SelectView } from 'particle-dev-views';
import { packageName } from '../utils/package-helper';

let $$ = null;
let fs = null;
let path = null;

export default class SelectFirmwareView extends SelectView {
	initialize() {
		super.initialize(...arguments);

		({ $$ } = require('atom-space-pen-views'));
		if (path == null) {
			path = require('path');
		}
		if (fs == null) {
			fs = require('fs-plus');
		}

		this.prop('id', 'select-firmware-view');
		this.addClass(packageName());
	}

	viewForItem(item) {
		return $$(function render() {
			const stats = fs.statSync(item);
			this.li({ class: 'two-lines' }, () => {
				this.div({ class: 'primary-line' }, path.basename(item));
				this.div({ class: 'secondary-line' }, stats.ctime.toLocaleString());
			});
		});
	}

	confirmed(item) {
		this.hide();
		return atom.particleDev.emitter.emit(`${packageName()}:flash-cloud`,
			{ firmware: item });
	}
}
