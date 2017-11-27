'use babel';

import { View } from 'atom-space-pen-views';
import { packageName } from '../utils/package-helper';

let CompositeDisposable = null;
let shell = null;
let $ = null;
let spark = null;

export default class StatusBarView extends View {
	static content() {
		this.div(() => {
			this.div({ id: 'logo-tile', class: `${packageName()} inline-block`, outlet: 'logoTile' }, () => {
				this.img({ src: `atom://${packageName()}/images/logo.png` });
			});
			this.div({ id: 'login-status-tile', class: `${packageName()} inline-block`, outlet: 'loginStatusTile' });
			this.div({ id: 'current-device-tile', class: `${packageName()} inline-block hidden`, outlet: 'currentCoreTile' }, () => {
				this.span({ class: 'platform-icon', outlet: 'platformIcon', title: 'Current target device' }, () => {
					this.a({ click: 'selectCore' });
				});
			});
			this.span({ id: 'compile-status-tile', class: `${packageName()} inline-block hidden`, outlet: 'compileStatusTile' }, () => {
				this.span({ id: 'compile-working' }, () => {
					this.span({ class: 'three-quarters' });
					this.a('Compiling in the cloud...');
				});
				this.a({ id: 'compile-failed', click: 'showErrors', class:'icon icon-stop' });
				this.a({ id: 'compile-success', click: 'showFile', class:'icon icon-check' });
			});
			this.span({ id: 'log-tile', class: `${packageName()} inline-block`, outlet: 'logTile' });
			this.div({ id: 'build-target-tile', class: `${packageName()} inline-block` }, () => {
				// TODO: maybe use a beaker icon for prerelease?
				this.span({ type: 'button', class: 'icon icon-tag inline-block', outlet: 'currentBuildTargetTile', title: 'Current build target', click: 'selectBuildTarget' }, 'Latest');
			});
		});
	}

	constructor(main) {
		super(...arguments);
		this.main = main;
		this.setup();
		this.main.profilesDefer.promise.then(() => {
			this.updateBuildTarget();
			this.main.profileManager._onCurrentTargetPlatformChanged(() => {
				this.updateBuildTarget();
			});
		});
	}

	initialize(serializeState) { }

	setup() {
		({ $ } = require('atom-space-pen-views'));
		({ CompositeDisposable } = require('atom'));

		this.disposables = new CompositeDisposable;
		this.workspaceElement = atom.views.getView(atom.workspace);

		this.getAttributesPromise = null;
		this.interval = null;

		const commands = {};
		atom.particleDev.emitter.on('update-login-status', () => this.updateLoginStatus());
		commands[`${packageName()}:update-core-status`] = () => this.updateCoreStatus();
		commands[`${packageName()}:update-compile-status`] = () => this.updateCompileStatus();
		commands[`${packageName()}:update-build-target`] = () => this.updateBuildTarget();
		return this.disposables.add(atom.commands.add('atom-workspace', commands));
	}

	// Returns an object that can be retrieved when package is activated
	serialize() {}

	// Tear down any state and detach
	destroy() {}

	addTiles(statusBar) {
		statusBar.addLeftTile({ item: this.logoTile, priority: 100 });
		statusBar.addLeftTile({ item: this.loginStatusTile, priority: 110 });
		statusBar.addLeftTile({ item: this.currentCoreTile, priority: 120 });
		statusBar.addLeftTile({ item: this.compileStatusTile, priority: 130 });
		statusBar.addLeftTile({ item: this.logTile, priority: 140 });
		statusBar.addLeftTile({ item: this.currentBuildTargetTile, priority: 201 });
	}

	// Callback triggering selecting core command
	selectCore() {
		return atom.commands.dispatch(this.workspaceElement, `${packageName()}:select-device`);
	}

	// Callback triggering selecting build target command
	selectBuildTarget() {
		return atom.commands.dispatch(this.workspaceElement, `${packageName()}:select-build-target`);
	}

	// Callback triggering showing compile errors command
	showErrors() {
		return atom.commands.dispatch(this.workspaceElement, `${packageName()}:show-compile-errors`);
	}

	// Opening file in Finder/Explorer
	showFile() {
		if (shell == null) {
			shell = require('shell');
		}
		const rootPath = atom.project.getPaths()[0];
		const compileStatus = this.main.profileManager.getLocal('compile-status');
		return shell.showItemInFolder(rootPath + '/' + compileStatus.filename);
	}

	// Get current core's status from the cloud
	getCurrentCoreStatus() {
		if (!this.main.profileManager.hasCurrentDevice) {
			return;
		}

		const statusElement = this.currentCoreTile.find('a');
		this.currentCoreTile.removeClass('online');

		spark = require('spark');
		spark.login({ accessToken: this.main.profileManager.accessToken });
		this.getAttributesPromise = spark.getAttributes(this.main.profileManager.currentDevice.id);
		return this.getAttributesPromise.then(e => {
			this.main.profileManager.setLocal('variables', {});
			this.main.profileManager.setLocal('functions', []);

			if (!e) {
				return;
			}

			// Check if current core is still available
			if (e.error) {
				this.main.profileManager.clearCurrentDevice();
				clearInterval(this.interval);
				this.interval = null;
				this.updateCoreStatus();
			} else {
				if (e.connected) {
					this.currentCoreTile.addClass('online');
				}

				this.main.profileManager.setLocal('current_core_name', e.name);
				if (!e.name) {
					statusElement.text('Unnamed');
				} else {
					statusElement.text(e.name);
				}

				this.main.profileManager.setLocal('variables', e.variables);
				this.main.profileManager.setLocal('functions', e.functions);

				// Periodically check if core is online
				if (!this.interval) {
					this.interval = setInterval(() => {
						return this.updateCoreStatus();
					}
						, 30000);
				}
			}

			atom.commands.dispatch(this.workspaceElement, `${packageName()}:core-status-updated`);
			this.getAttributesPromise = null;
		}

			, e => {
			console.error(e);

			atom.commands.dispatch(this.workspaceElement, `${packageName()}:core-status-updated`);
			this.getAttributesPromise = null;
		});
	}

	// Update current core's status
	updateCoreStatus() {
		const statusElement = this.currentCoreTile.find('a');
		this.platformIcon.removeClass();
		this.platformIcon.addClass('platform-icon');

		if (this.main.profileManager.hasCurrentDevice) {
			let currentCore = this.main.profileManager.currentDevice.name;
			if (!currentCore) {
				currentCore = 'Unnamed';
			}
			statusElement.text(currentCore);
			this.platformIcon.addClass(`platform-icon-${this.main.profileManager.currentDevice.platformId}`);

			return this.getCurrentCoreStatus();
		} else {
			this.currentCoreTile.removeClass('online');
			statusElement.text('No devices selected');
		}
	}

	// Update login status
	updateLoginStatus() {
		this.loginStatusTile.empty();

		if (this.main.profileManager.isLoggedIn) {
			const { username } = this.main.profileManager;
			this.loginStatusTile.text(username);

			this.currentCoreTile.removeClass('hidden');
			this.updateCoreStatus();
		} else {
			const loginButton = $('<a/>').text('Click to log in to Particle Cloud...');
			this.loginStatusTile.append(loginButton);
			loginButton.on('click', () => {
				return atom.commands.dispatch(this.workspaceElement, `${packageName()}:login`);
			});

			this.currentCoreTile.addClass('hidden');
		}

		return atom.commands.dispatch(this.workspaceElement, `${packageName()}:update-menu`);
	}

	updateCompileStatus() {
		this.compileStatusTile.addClass('hidden');
		const compileStatus = this.main.profileManager.getLocal('compile-status');

		if (compileStatus) {
			let subElement;
			this.compileStatusTile.removeClass('hidden');
			this.compileStatusTile.find('>').hide();

			if (compileStatus.working) {
				this.compileStatusTile.find('#compile-working').show();
			} else if (compileStatus.errors) {
				subElement = this.compileStatusTile.find('#compile-failed');
				if (compileStatus.errors.length === 1) {
					subElement.text('One error');
				} else {
					subElement.text(compileStatus.errors.length + ' errors');
				}
				subElement.show();
			} else if (compileStatus.error) {
				subElement = this.compileStatusTile.find('#compile-failed');
				subElement.text(compileStatus.error);
				subElement.show();
			} else {
				this.compileStatusTile.find('#compile-success')
					.text('Success!')
					.show();
			}
		}
	}

	updateBuildTarget() {
		return this.main.getBuildTargets().then(targets => {
			let currentBuildTarget = this.main.getCurrentBuildTarget();
			// Clear build target if it doesn't exist for current platform
			const targetExists = targets.reduce((acc, val) => {
				return acc || (val.version === currentBuildTarget);
			}
				, false);
			if (!targetExists) {
				currentBuildTarget = undefined;
			}

			if (!currentBuildTarget) {
				const latestVersion = targets.reduce((acc, val) => {
					return acc || (!val.prerelease || atom.config.get(`${packageName()}.defaultToFirmwarePrereleases`) ? val.version : undefined);
				}
					, undefined);
				currentBuildTarget = latestVersion;
			}

			this.main.setCurrentBuildTarget(currentBuildTarget);

			if (!currentBuildTarget) {
				currentBuildTarget = 'Latest';
			}
			this.currentBuildTargetTile.text(currentBuildTarget);
		});
	}

	setStatus(text, type = null) {
		this.logTile.text(text).removeClass();

		if (type) {
			this.logTile.addClass(`text-${type}`);
		}
	}

	clear() {
		this.logTile.fadeOut(() => {
			this.setStatus('');
			this.logTile.show();
		});
	}

	clearAfter(delay) {
		setTimeout(() => {
			this.clear();
		}
			, delay);
	}
}
