'use babel';

import { View, $ } from 'atom-space-pen-views';
import { MiniEditorView } from 'particle-dev-views';
import { packageName } from '../utils/package-helper';

let CompositeDisposable = null;
let _s = null;
let spark = null;
let validator = null;

export default class LoginView extends View {
	static content() {
		this.div({ id: 'login-view', class: packageName() }, () => {
			this.div({ class: 'block' }, () => {
				this.span('Log in to Particle Cloud ');
				this.span({ class: 'text-subtle' }, () => {
					this.text('Close this dialog with the ');
					this.span({ class: 'highlight' }, 'esc');
					this.span(' key');
				});
			});
			this.subview('emailEditor', new MiniEditorView('Could I please have an email address?'));
			this.subview('passwordEditor', new MiniEditorView('and a password?'));
			this.div({ class: 'text-error block', outlet: 'errorLabel' });
			this.div({ class: 'block' }, () => {
				this.button({ click: 'login', id: 'loginButton', class: 'btn btn-primary', outlet: 'loginButton', tabindex: 3 }, 'Log in');
				this.button({ click: 'cancel', id: 'cancelButton', class: 'btn', outlet: 'cancelButton', tabindex: 4 }, 'Cancel');
				this.span({ class: 'three-quarters inline-block hidden', outlet: 'spinner' });
				this.a({ href: 'https://build.particle.io/forgot-password', class: 'pull-right', tabindex: 5 }, 'Forgot password?');
			});
		});
	}

	initialize(serializeState) {
		({ CompositeDisposable } = require('atom'));
		if (_s == null) {
			_s = require('underscore.string');
		}

		this.panel = atom.workspace.addModalPanel({ item: this, visible: false });
		this.workspaceElement = atom.views.getView(atom.workspace);

		this.disposables = new CompositeDisposable;
		this.disposables.add(atom.commands.add('atom-workspace',
			'core:cancel', () => {
				return atom.commands.dispatch(this.workspaceElement, `${packageName()}:cancel-login`);
			},
			'core:close', () => {
				return atom.commands.dispatch(this.workspaceElement, `${packageName()}:cancel-login`);
			})
		);


		this.loginPromise = null;
		this.main = null;

		this.emailModel = this.emailEditor.editor.getModel();
		this.emailEditor.editor.element.setAttribute('tabindex', 1);
		this.passwordModel = this.passwordEditor.editor.getModel();
		this.passwordEditor.editor.element.setAttribute('tabindex', 2);
		const passwordElement = $(this.passwordEditor.editor.element.rootElement);
		passwordElement.find('div.lines').addClass('password-lines');
		this.passwordModel.onDidChange(() => {
			const string = this.passwordModel.getText().split('').map(() => '*').join('');

			passwordElement.find('#password-style').remove();
			passwordElement.append(`<style id="password-style">.password-lines .line span.syntax--text:before {content:"${string}";}</style>`);
		});
		return this.disposables.add(atom.commands.add(this.passwordEditor.editor.element, {
			'core:confirm': () => {
				return this.login();
			}
		}
		)
		);
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

	show() {
		this.panel.show();
		this.emailEditor.editor.focus();
	}

	hide() {
		this.panel.hide();
		this.unlockUi();
		this.clearErrors();
		this.emailModel.setText('');
		this.passwordModel.setText('');
		this.errorLabel.hide();
	}

	cancel(event, element) {
		if (this.loginPromise) {
			this.loginPromise = null;
		}
		this.hide();
	}

	cancelCommand() {
		this.cancel();
	}

	// Remove errors from inputs
	clearErrors() {
		this.emailEditor.editor.removeClass('editor-error');
		this.passwordEditor.editor.removeClass('editor-error');
	}

	// Test input's values
	validateInputs() {
		if (validator == null) {
			validator = require('validator');
		}

		this.clearErrors();

		this.email = _s.trim(this.emailModel.getText());
		this.password = _s.trim(this.passwordModel.getText());

		let isOk = true;

		if ((this.email === '') || (!validator.isEmail(this.email))) {
			this.emailEditor.editor.addClass('editor-error');
			isOk = false;
		}

		if (this.password === '') {
			this.passwordEditor.editor.addClass('editor-error');
			isOk = false;
		}

		return isOk;
	}

	// Unlock inputs and buttons
	unlockUi() {
		this.emailEditor.setEnabled(true);
		this.passwordEditor.setEnabled(true);
		this.loginButton.removeAttr('disabled');
	}

	// Login via the cloud
	login(event, element) {
		if (!this.validateInputs()) {
			return false;
		}

		this.emailEditor.setEnabled(false);
		this.passwordEditor.setEnabled(false);
		this.loginButton.attr('disabled', 'disabled');
		this.spinner.removeClass('hidden');
		this.errorLabel.hide();

		spark = require('spark');
		this.loginPromise = spark.login({ username:this.email, password:this.password });
		return this.loginPromise.then(e => {
			this.spinner.addClass('hidden');
			if (!this.loginPromise) {
				return;
			}
			this.main.profileManager.username = this.email;
			this.main.profileManager.accessToken = e.access_token;
			atom.particleDev.emitter.emit('update-login-status');
			this.loginPromise = null;

			this.cancel();
		}

			, e => {
			this.spinner.addClass('hidden');
			if (!this.loginPromise) {
				return;
			}
			this.unlockUi();
			if (e.code === 'ENOTFOUND') {
				this.errorLabel.text(`Error while connecting to ${e.hostname}`);
			} else if (e.message === 'invalid_grant') {
				this.errorLabel.text('Invalid email or password');
			} else {
				this.errorLabel.text(e);
			}

			this.errorLabel.show();
			this.loginPromise = null;
		});
	}

	// Logout
	logout() {
		this.main.profileManager.clearCredentials();
		return atom.particleDev.emitter.emit('update-login-status');
	}
}
