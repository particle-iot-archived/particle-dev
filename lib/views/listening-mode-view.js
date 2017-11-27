'use babel';

import { View } from 'atom-space-pen-views';
import { packageName } from '../utils/package-helper';
let SerialHelper = null;

export default class ListeningModeView extends View {
	static content() {
		this.div(() => {
			this.h1('Waiting for device...');
			this.p(() => {
				this.img({ src: `atom://${packageName()}/images/listening.gif` });
			});
			this.p("Check if your device is connected via USB and it's in listening mode (LED blinking blue).");
			this.div({ class: 'block' }, () => {
				this.button({ click: 'cancel', class: 'btn' }, 'Cancel');
			});
		});
	}

	initialize(delegate) {
		const { CompositeDisposable } = require('atom');
		SerialHelper = require('../utils/serial-helper');

		this.prop('id', 'listening-mode-view');
		this.addClass(packageName());
		this.panel = atom.workspace.addModalPanel({ item: this, visible: false });

		this.disposables = new CompositeDisposable;
		this.workspaceElement = atom.views.getView(atom.workspace);
		this.disposables.add(atom.commands.add('atom-workspace',
			'core:cancel', () => this.cancel(),
			'core:close', () => this.cancel())
		);

		// Interval for automatic dialog dismissal
		this.interval = setInterval(() => {
			const promise = SerialHelper.listPorts();
			return promise.then(ports => {
				if (ports.length > 0) {
					// Hide dialog
					this.cancel();
					// Try to identify found ports
					return atom.commands.dispatch(this.workspaceElement, delegate);
				}
			}
				, e => console.error(e));
		}
			, 1000);
	}

	serialize() {}

	destroy() {
		this.cancel();
		const panelToDestroy = this.panel;
		this.panel = null;
		return (panelToDestroy != null ? panelToDestroy.destroy() : undefined);
	}

	show() {
		return this.panel.show();
	}

	hide() {
		return this.panel.hide();
	}

	cancel(event, element) {
		clearInterval(this.interval);
		return this.hide();
	}
}
