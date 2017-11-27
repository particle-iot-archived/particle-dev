'use babel';

import { DialogView } from 'particle-dev-views';
import { packageName } from '../utils/package-helper';
let _s = null;
let spark = null;

export default class RenameCoreView extends DialogView {
	constructor(initialName) {
		initialName = initialName ? initialName : '';
		super({
			prompt: 'Enter new name for this Core',
			initialText: initialName,
			select: true,
			iconClass: '',
			hideOnBlur: false
		});

		this.renamePromise = null;
		this.main = null;
		this.prop('id', 'rename-core-view');
		this.addClass(packageName());
		this.workspaceElement = atom.views.getView(atom.workspace);
	}

	onConfirm(newName) {
		if (_s == null) {
			_s = require('underscore.string');
		}

		this.miniEditor.editor.removeClass('editor-error');
		newName = _s.trim(newName);
		if (newName === '') {
			this.miniEditor.editor.addClass('editor-error');
		} else {
			if (spark == null) {
				spark = require('spark');
			}
			spark.login({ accessToken: this.main.profileManager.accessToken });
			this.renamePromise = spark.renameCore(this.main.profileManager.currentDevice.id, newName);
			this.miniEditor.setLoading(true);
			this.miniEditor.setEnabled(false);

			return this.renamePromise.then(e => {
				this.miniEditor.setLoading(false);
				if (!this.renamePromise) {
					return;
				}

				const { currentDevice } = this.main.profileManager;
				currentDevice.name = newName;
				this.main.profileManager.currentDevice = currentDevice;

				atom.commands.dispatch(this.workspaceElement, `${packageName()}:update-core-status`);
				atom.commands.dispatch(this.workspaceElement, `${packageName()}:update-menu`);
				this.renamePromise = null;

				return this.close();
			}

				, e => {
				let message;
				this.miniEditor.setLoading(false);
				this.renamePromise = null;
				this.miniEditor.setEnabled(true);
				if (e.code === 'ENOTFOUND') {
					message = `Error while connecting to ${e.hostname}`;
				} else {
					({ message } = e);
				}

				return atom.confirm({
					message: 'Error',
					detailedMessage: message
				});
			});
		}
	}
}
