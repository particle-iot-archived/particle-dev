'use babel';

import { DialogView } from 'particle-dev-views';
import { packageName } from '../utils/package-helper';
let _s = null;

export default class ClaimCoreView extends DialogView {
	constructor() {
		super({
			prompt: 'Enter device ID (hex string)',
			initialText: '',
			select: false,
			iconClass: '',
			hideOnBlur: false
		});

		this.claimPromise = null;
		this.main = null;
		this.prop('id', 'claim-core-view');
		this.addClass(packageName());
		this.workspaceElement = atom.views.getView(atom.workspace);
	}

	// When deviceID is submited
	onConfirm(deviceID) {
		if (_s == null) {
			_s = require('underscore.string');
		}

		// Remove any errors
		this.miniEditor.editor.removeClass('editor-error');
		// Trim deviceID from any whitespaces
		deviceID = _s.trim(deviceID);

		if (deviceID === '') {
			// Empty deviceID is not allowed
			this.miniEditor.editor.addClass('editor-error');
		} else {
			// Lock input
			this.miniEditor.setEnabled(false);
			this.miniEditor.setLoading(true);

			const spark = require('spark');
			spark.login({ accessToken: this.main.profileManager.accessToken });

			// Claim core via API
			this.claimPromise = spark.claimCore(deviceID);
			this.setLoading(true);
			return this.claimPromise.then(e => {
				this.miniEditor.setLoading(false);
				if (e.ok) {
					if (!this.claimPromise) {
						return;
					}

					// Set current core in settings
					const device = new this.main.profileManager.Device();
					device.id = e.id;
					this.main.profileManager.currentDevice = device;

					// Refresh UI
					atom.commands.dispatch(this.workspaceElement, `${packageName()}:update-core-status`);
					atom.commands.dispatch(this.workspaceElement, `${packageName()}:update-menu`);

					this.claimPromise = null;
					return this.close();
				} else {
					this.miniEditor.setEnabled(true);
					this.miniEditor.editor.addClass('editor-error');
					if (e.errors.length === 2) {
						delete e.errors[1];
					}
					this.showError(e.errors);

					this.claimPromise = null;
				}
			}

				, e => {
				this.setLoading(false);
				// Show error
				return;
				this.miniEditor.setEnabled(true);

				if (e.code === 'ENOTFOUND') {
					const message = `Error while connecting to ${e.hostname}`;
					this.showError(message);
				} else {
					this.miniEditor.editor.addClass('editor-error');
					this.showError(e.errors);
				}

				this.claimPromise = null;
			});
		}
	}
}
