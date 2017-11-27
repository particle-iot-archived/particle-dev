'use babel';

import { View } from 'atom-space-pen-views';
import { MiniEditorView } from 'particle-dev-views';
import { packageName } from '../utils/package-helper';

let _s = null;
let SerialHelper = null;

export default class WifiCredentialsView extends View {
	static content() {
		this.div({ id: 'wifi-credentials-view', class: packageName() }, () => {
			this.div({ class: 'block' }, () => {
				this.span('Enter WiFi Credentials ');
				this.span({ class: 'text-subtle' }, () => {
					this.text('Close this dialog with the ');
					this.span({ class: 'highlight' }, 'esc');
					this.span(' key');
				});
			});
			this.subview('ssidEditor', new MiniEditorView('SSID'));
			this.div({ class: 'security' }, () => {
				this.label(() => {
					this.input({ type: 'radio', name: 'security', value: '0', checked: 'checked', change: 'change' });
					this.span('Unsecured');
				});
				this.label(() => {
					this.input({ type: 'radio', name: 'security', value: '1', change: 'change' });
					this.span('WEP');
				});
				this.label(() => {
					this.input({ type: 'radio', name: 'security', value: '2', change: 'change' });
					this.span('WPA');
				});
				this.label(() => {
					this.input({ type: 'radio', name: 'security', value: '3', change: 'change' });
					this.span('WPA2');
				});
			});
			this.subview('passwordEditor', new MiniEditorView('and a password?'));
			this.div({ class: 'text-error block', outlet: 'errorLabel' });
			this.div({ class: 'block' }, () => {
				this.button({ click: 'save', id: 'saveButton', class: 'btn btn-primary', outlet: 'saveButton' }, 'Save');
				this.button({ click: 'cancel', id: 'cancelButton', class: 'btn', outlet: 'cancelButton' }, 'Cancel');
				this.span({ class: 'three-quarters inline-block hidden', outlet: 'spinner' });
			});
		});
	}

	initialize(serializeState) {
		const { CompositeDisposable } = require('atom');
		if (_s == null) {
			_s = require('underscore.string');
		}
		SerialHelper = require('../utils/serial-helper');

		this.panel = atom.workspace.addModalPanel({ item: this, visible: false });
		this.workspaceElement = atom.views.getView(atom.workspace);

		this.disposables = new CompositeDisposable;
		this.disposables.add(atom.commands.add('atom-workspace',
			'core:cancel', () => this.remove(),
			'core:close', () => this.remove())
		);

		this.disposables.add(atom.commands.add(this.passwordEditor.editor.element, {
			'core:confirm': () => {
				return this.save();
			}
		}
		)
		);

		this.security = '0';
		this.passwordEditor.addClass('hidden');

		this.serialWifiConfigPromise = null;
	}


	// Returns an object that can be retrieved when package is activated
	serialize() {}

	// Tear down any state and detach
	destroy() {
		const panelToDestroy = this.panel;
		this.panel = null;
		if (panelToDestroy != null) {
			panelToDestroy.destroy();
		}

		return this.disposables.dispose();
	}

	show(ssid=null, security=null) {
		this.panel.show();
		if (ssid) {
			this.ssidEditor.editor.getModel().setText(ssid);
		} else {
			this.ssidEditor.editor.click();
		}

		if (security) {
			const input = this.find(`input[name=security][value=${security}]`);
			input.attr('checked', 'checked');
			input.change();
		}

		this.errorLabel.hide();
	}

	hide() {
		if (this.hasParent()) {
			return this.detach();
		}
	}

	cancel(event, element) {
		if (this.loginPromise) {
			this.loginPromise = null;
		}
		this.unlockUi();
		this.clearErrors();
		return this.hide();
	}

	cancelCommand() {
		return this.cancel();
	}

	// Remove errors from inputs
	clearErrors() {
		this.ssidEditor.editor.removeClass('editor-error');
		this.passwordEditor.editor.removeClass('editor-error');
	}

	change() {
		this.security = this.find('input[name=security]:checked').val();

		if (this.security === '0') {
			this.passwordEditor.addClass('hidden');
		} else {
			this.passwordEditor.removeClass('hidden');
			this.passwordEditor.editor.click();
		}
	}

	// Test input's values
	validateInputs() {
		this.clearErrors();

		this.ssid = _s.trim(this.ssidEditor.editor.getModel().getText());
		this.password = _s.trim(this.passwordEditor.editor.getModel().getText());

		let isOk = true;

		if (this.ssid === '') {
			this.ssidEditor.editor.addClass('editor-error');
			isOk = false;
		}

		if ((this.security !== '0') && (this.password === '')) {
			this.passwordEditor.editor.addClass('editor-error');
			isOk = false;
		}

		return isOk;
	}

	// Unlock inputs and buttons
	unlockUi() {
		this.ssidEditor.setEnabled(true);
		this.find('input[name=security]').removeAttr('disabled');
		this.passwordEditor.setEnabled(true);
		this.saveButton.removeAttr('disabled');
	}

	save() {
		if (!this.validateInputs()) {
			return false;
		}

		this.ssidEditor.setEnabled(false);
		this.find('input[name=security]').attr('disabled', 'disabled');
		this.passwordEditor.setEnabled(false);
		this.saveButton.attr('disabled', 'disabled');
		this.spinner.removeClass('hidden');
		this.errorLabel.hide();

		this.serialWifiConfigPromise = SerialHelper.serialWifiConfig(this.port, this.ssid, this.password, this.security);
		return this.serialWifiConfigPromise.done(e => {
			this.spinner.addClass('hidden');

			this.cancel();
			this.serialWifiConfigPromise = null;
		}
			, e => {
			this.spinner.addClass('hidden');
			this.unlockUi();
			this.errorLabel.text(e).show();
			this.serialWifiConfigPromise = null;
		});
	}
}
