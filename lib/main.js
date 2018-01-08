'use babel';

import pipeline from 'when/pipeline';

import { packageName } from './utils/package-helper';

let CompositeDisposable = null;
let Emitter = null;
let fs = null;
let settings = null;
let utilities = null;
let path = null;
let _s = null;
let url = null;
let errorParser = null;
let libraryManager = null;
let semver = null;
let compilationContext = null;

export default {
	// Local modules for JIT require
	MenuManager: null,
	SerialHelper: null,
	StatusView: null,
	LoginView: null,
	SelectCoreView: null,
	RenameCoreView: null,
	ClaimCoreView: null,
	IdentifyCoreView: null,
	ListeningModeView: null,
	SelectPortView: null,
	CompileErrorsView: null,
	SelectFirmwareView: null,
	File: null,

	statusView: null,
	loginView: null,
	selectCoreView: null,
	renameCoreView: null,
	claimCoreView: null,
	identifyCoreView: null,
	listeningModeView: null,
	selectPortView: null,
	compileErrorsView: null,
	selectFirmwareView: null,
	spark: null,
	toolbar: null,

	removePromise: null,
	listPortsPromise: null,
	compileCloudPromise: null,
	flashCorePromise: null,

	activatePromise: null,

	analytics: null,

	activate(state) {
		// Require modules on activation
		if (this.analytics == null) {
			this.analytics = require('./contexts/analytics');
		}
		if (this.StatusView == null) {
			this.StatusView = require('./views/status-bar-view');
		}
		({ File: this.File } = require('atom'));


		this.workspaceElement = atom.views.getView(atom.workspace);
		({ CompositeDisposable, Emitter } = require('atom'));
		this.disposables = new CompositeDisposable;
		this.contextMenus = new CompositeDisposable;
		this.emitter = new Emitter;
		atom.particleDev = {
			emitter: this.emitter
		};

		// Install packages we depend on
		require('atom-package-deps').install(packageName(), true);

		// Create promises for consumed services
		this.profilesPromise = new Promise((resolve, reject) => this.profilesResolve = resolve);
		activatePromise = Promise.all([
			this.profilesPromise,
			new Promise((resolve, reject) => this.statusBarResolve = resolve),
			new Promise((resolve, reject) => this.toolBarResolve = resolve),
			new Promise((resolve, reject) => this.consolePanelResolve = resolve)
		]).then(() => {
			return this.ready();
		});
		return activatePromise;
	},

	deactivate() {
		if (this.statusView != null) {
			this.statusView.destroy();
		}
		this.emitter.dispose();
		this.disposables.dispose();
		this.contextMenus.dispose();
		if (this.statusBarTile != null) {
			this.statusBarTile.destroy();
		}
		this.statusBarTile = null;
		if (this.toolBar != null) {
			this.toolBar.removeItems();
		}
		this.toolBar = null;
	},

	serialize() {},

	ready() {
		// Initialize status bar view
		this.statusView = new this.StatusView(this);
		this.statusView.addTiles(this.statusBar);
		this.statusView.updateLoginStatus();

		if (this.MenuManager == null) {
			this.MenuManager = require('./utils/menu-manager')(this.profileManager);
		}
		// Hook up commands
		this._registerCommands();
		// Hook up events
		this._registerEventListeners();
		// Update menu (default one in CSON file is empty)
		this.MenuManager.update();
		this._registerUrlOpener();
		this._registerContextMenus();

		this.updateToolbarButtons();

		// Monitoring changes in settings
		this.profileManager.on('current-profile-changed', () => this._onProfileChanged());
		this.profileManager.on('current-profile-updated', () => this._onProfileChanged());

		this.disposables.add(this.watchEditors());
		return this.disposables.add(atom.project.onDidChangePaths(() => {
			return this.updateToolbarButtons();
		}));
	},

	provideParticleDev() {
		return this;
	},

	consumeStatusBar(statusBar) {
		this.statusBar = statusBar;
		this.statusBarResolve(this.statusBar);
	},

	consumeToolBar(toolBar) {
		this.toolBar = toolBar(`${packageName()}-tool-bar`);

		this.toolBar.addSpacer();
		this.flashButton = this.toolBar.addButton({
			icon: 'flash',
			callback: `${packageName()}:flash-cloud`,
			tooltip: 'Compile in cloud and upload code using cloud',
			iconset: 'ion',
			priority: 510
		});
		this.compileButton = this.toolBar.addButton({
			icon: 'android-cloud-done',
			callback: `${packageName()}:compile-cloud`,
			tooltip: 'Compile in cloud and show errors if any',
			iconset: 'ion',
			priority: 520
		});

		this.toolBar.addSpacer({
			priority: 530 });

		this.toolBar.addButton({
			icon: 'document-text',
			callback() {
				return require('shell').openExternal('https://docs.particle.io/');
			},
			tooltip: 'Opens reference at docs.particle.io',
			iconset: 'ion',
			priority: 540
		});
		this.coreButton = this.toolBar.addButton({
			icon: 'pinpoint',
			callback: `${packageName()}:select-device`,
			tooltip: 'Select which device you want to work on',
			iconset: 'ion',
			priority: 550
		});
		this.toolBar.addButton({
			icon: 'stats-bars',
			callback() {
				return require('shell').openExternal('https://console.particle.io/');
			},
			tooltip: 'Opens Console at console.particle.io',
			iconset: 'ion',
			priority: 560
		});
		this.toolBar.addButton({
			icon: 'usb',
			callback: `${packageName()}:show-serial-monitor`,
			tooltip: 'Show serial monitor',
			iconset: 'ion',
			priority: 570
		});

		this.toolBarResolve(this.toolBar);
	},

	consumeConsolePanel(consolePanel) {
		this.consolePanel = consolePanel;
		this.consolePanelResolve(this.consolePanel);
	},

	consumeProfiles(profileManager) {
		this.profileManager = profileManager;
		this.profilesResolve(this.profileManager);
	},

	config: {
		// Delete .bin file after flash
		deleteFirmwareAfterFlash: {
			type: 'boolean',
			default: true
		},

		// Delete old .bin files on successful compile
		deleteOldFirmwareAfterCompile: {
			type: 'boolean',
			default: true
		},

		// Save all files before compile
		saveAllBeforeCompile: {
			type: 'boolean',
			default: true
		},

		// Files ignored when compiling
		filesExcludedFromCompile: {
			type: 'string',
			default: '.ds_store, .jpg, .gif, .png, .include, .ignore, Thumbs.db, .git, .bin'
		},

		// Show prereleases in build targets
		showFirmwarePrereleases: {
			type: 'boolean',
			default: true
		},

		// Allow prereleases to be used as default
		defaultToFirmwarePrereleases: {
			type: 'boolean',
			default: false
		}
	},

	// Require view's module and initialize it
	initView(name) {
		if (_s == null) {
			_s = require('underscore.string');
		}

		name += '-view';
		let className = '';
		for (let part of name.split('-')) {
			className += _s.capitalize(part);
		}

		if (this[className] == null) {
			this[className] = require(`./views/${name}`);
		}
		const key = className.charAt(0).toLowerCase() + className.slice(1);
		if (this[key] == null) {
			this[key] = new (this[className])();
		}
		return this[key];
	},

	// "Decorator" which runs callback only when user is logged in
	loginRequired(callback) {
		if (!this.profileManager.isLoggedIn) {
			return;
		}

		if (this.spark == null) {
			this.spark = require('spark');
		}
		this.spark.login({
			accessToken: this.profileManager.accessToken });

		if (this.profileManager.apiUrl) {
			this.spark.api.baseUrl = this.profileManager.apiUrl;
		}

		return callback();
	},

	// "Decorator" which runs callback only when user is logged in and has core selected
	deviceRequired(callback) {
		return this.loginRequired(() => {
			const self = this;
			if (!this.profileManager.hasCurrentDevice) {
				var notification = atom.notifications.addInfo('Please select a device', {
					buttons: [
						{ text: 'Select Device...', onDidClick: () => {
							// this is NotificationElement (UI), not Notification (the model)
							// hmm...doesn't seem to even be NotificationElement but the raw DOM object
							const view = atom.views.getView(notification);
							view.removeNotification();
							return this.emitter.emit(`${packageName()}:select-device`, { callback });
						}
						}
					]
				});
				return;
			}
			return callback();
		});
	},

	// "Decorator" which runs callback only when there's project set
	projectRequired(callback) {
		if (this.getProjectDir() === null) {
			atom.notifications.addInfo('Please open a directory with your project');
			return;
		}

		return callback();
	},

	// "Decorator" which tests if we're using at least 0.5.3 when compiling with libraries
	minBuildTargetRequired(callback) {
		if ((this.isProject() || this.isLibrary()) && this.profileManager.hasCurrentDevice) {
			if (semver == null) {
				semver = require('semver');
			}
			const targetBuild = this.getCurrentBuildTarget();
			const currentTargetPlatform = this.profileManager.currentTargetPlatform;
			const isBuildpackPlatform = [0, 6, 8, 10].indexOf(currentTargetPlatform) > -1;
			if (isBuildpackPlatform && targetBuild && semver.lt(targetBuild, '0.5.3')) {
				atom.notifications.addError('This project is only compatible with Particle system firmware v0.5.3 or later. You will need to update the system firmware running on your Electron before you can flash this project to your device.');
				return;
			}
		}

		return callback();
	},

	// Open view in a panel
	openPane(uri, location, packageName) {
		if (location == null) {
			location = 'right';
		}
		if (packageName) {
			uri = `${packageName}://editor/` + uri;
		} else {
			uri = `${packageName()}://editor/` + uri;
		}

		return atom.workspace.open(uri, { searchAllPanes: true, split: location });
	},

	isCompileAvailable() {
		return (!this.isLibrary() || this.isLibraryExampleInFocus());
	},

	isLibraryExampleInFocus(editor) {
		if (editor == null) {
			editor = atom.workspace.getActiveTextEditor();
		}
		if (editor) {
			const file = editor.getPath();
			const result =  this.isLibraryExampleSync(file);
			if (result) {
				return file;
			}
		}
	},

	// Enables/disables toolbar buttons based on log in state
	updateToolbarButtons() {
		if (!this.compileButton) {
			return;
		}
		if (this.profileManager.isLoggedIn) {
			this.compileButton.setEnabled(this.isCompileAvailable());
			this.coreButton.setEnabled(true);

			if (this.profileManager.hasCurrentDevice) {
				return this.flashButton.setEnabled(this.isCompileAvailable());
			} else {
				return this.flashButton.setEnabled(false);
			}
		} else {
			this.flashButton.setEnabled(false);
			this.compileButton.setEnabled(false);
			return this.coreButton.setEnabled(false);
		}
	},

	watchEditors() {
		return atom.workspace.onDidStopChangingActivePaneItem(panel => {
			if (atom.workspace.isTextEditor(panel) && this.isLibrary()) {
				return this.updateToolbarButtons();
			}
		});
	},

	processDirIncludes(dirname) {
		if (settings == null) {
			settings = require('./vendor/settings');
		}
		if (utilities == null) {
			utilities = require('./vendor/utilities');
		}

		dirname = path.resolve(dirname);
		const includesFile = path.join(dirname, settings.dirIncludeFilename);
		const ignoreFile = path.join(dirname, settings.dirExcludeFilename);
		let ignores = [];
		const includes = [
			'**/*.h',
			'**/*.hpp',
			'**/*.ino',
			'**/*.cpp',
			'**/*.c',
			'**/*.properties'
		];

		if (fs.existsSync(includesFile)) {
			// Grab and process all the files in the include file.
			// cleanIncludes = utilities.trimBlankLinesAndComments(utilities.readAndTrimLines(includesFile))
			// includes = utilities.fixRelativePaths dirname, cleanIncludes
			null;
		}

		const files = utilities.globList(dirname, includes);

		const notSourceExtensions = atom.config.get(`${packageName()}.filesExcludedFromCompile`).split(',');
		ignores = (notSourceExtensions.map((extension) => `**/*${_s.trim(extension).toLowerCase()}`));

		if (fs.existsSync(ignoreFile)) {
			const cleanIgnores = utilities.readAndTrimLines(ignoreFile);
			ignores = ignores.concat(utilities.trimBlankLinesAndComments(cleanIgnores));
		}

		const ignoredFiles = utilities.globList(dirname, ignores);
		return utilities.compliment(files, ignoredFiles);
	},

	// Function for selecting port or showing Listen dialog
	choosePort(delegate) {
		if (this.ListeningModeView == null) {
			this.ListeningModeView = require('./views/listening-mode-view');
		}
		if (this.SerialHelper == null) {
			this.SerialHelper = require('./utils/serial-helper');
		}
		this.listPortsPromise = this.SerialHelper.listPorts();
		return this.listPortsPromise.then(ports => {
			this.listPortsPromise = null;
			if (ports.length === 0) {
				// If there are no ports, show dialog with animation how to enter listening mode
				this.listeningModeView = new this.ListeningModeView(delegate);
				return this.listeningModeView.show();
			} else if (ports.length === 1) {
				return this.emitter.emit(delegate, { port: ports[0].comName });
			} else {
				// There are at least two ports so show them and ask user to choose
				if (this.SelectPortView == null) {
					this.SelectPortView = require('./views/select-port-view');
				}
				this.selectPortView = new this.SelectPortView(delegate);

				return this.selectPortView.show();
			}
		}
			, e => {
			return console.error(e);
		});
	},

	getPlatformSlug(id) {
		let slug = this.profileManager.knownTargetPlatforms[id];
		if (slug) {
			slug = slug.name;
		} else {
			slug = 'Unknown';
		}
		return _s.underscored(slug);
	},

	getCurrentBuildTarget() {
		return this.profileManager.getLocal('current-build-target');
	},

	setCurrentBuildTarget(value) {
		return this.profileManager.setLocal('current-build-target', value);
	},

	getBuildTargets() {
		return pipeline([
			() => {
				if (this.buildTargets) {
					return this.buildTargets;
				}
				return this.profileManager.apiClient.listBuildTargets();
			}
			, buildTargets => {
				this.buildTargets = buildTargets;
				if (!this.buildTargets) {
					return [];
				}

				if (semver == null) {
					semver = require('semver');
				}

				this.buildTargets.sort(function(a, b) {
					if (semver.eq(a.version, b.version)) {
						return 0;
					}
					if (semver.gt(a.version, b.version)) {
						return -1;
					} else {
						return 1;
					}
				});

				const showPrereleases = atom.config.get(`${packageName()}.showFirmwarePrereleases`);
				return this.buildTargets.filter(target => {
					return (target.platform === this.profileManager.currentTargetPlatform) && (showPrereleases || !target.prerelease);
				});
			}
		]);
	},

	getProjectDir() {
		if (fs == null) {
			fs = require('fs-plus');
		}

		const paths = atom.project.getDirectories();
		if (paths.length === 0) {
			return null;
		}

		// For now take first directory
		// FIXME: some way to let user choose which dir to use
		const projectPath = paths[0];

		if (!projectPath.existsSync()) {
			return null;
		}

		let projectDir = projectPath.getPath();
		if (!fs.lstatSync(projectDir).isDirectory()) {
			atom.project.removePath(projectDir);
			projectDir = projectPath.getParent().getPath();
			atom.project.addPath(projectDir);
			return projectDir;
		}
		return projectPath.getPath();
	},

	existsProjectFile(file) {
		if (path == null) {
			path = require('path');
		}
		const dir = this.getProjectDir();
		return dir && fs.existsSync(path.join(dir, file));
	},

	isProject() {
		return this.existsProjectFile('project.properties');
	},

	isLibrary() {
		return this.existsProjectFile('library.properties');
	},

	isLegacyLibrary() {
		return this.existsProjectFile('spark.json');
	},


	requestErrorHandler(error) {
		if (error.message === 'invalid_token') {
			this.statusView.setStatus('Token expired. Log in again', 'error');
			this.statusView.clearAfter(5000);
			return this.logout();
		}
	},

	// Show login dialog
	login() {
		this.initView('login');
		// You may ask why commands aren't registered in LoginView?
		// This way, we don't need to require/initialize login view until it's needed.
		const commands = {};
		commands[`${packageName}:cancel-login`] = () => this.loginView.cancelCommand();
		this.disposables.add(atom.commands.add('atom-workspace', commands));
		this.loginView.main = this;
		return this.loginView.show();
	},

	// Log out current user
	logout() {
		return this.loginRequired(() => {
			this.initView('login');

			this.loginView.main = this;
			return this.loginView.logout();
		});
	},

	// Show user's cores list
	selectCore(callback) {
		return this.loginRequired(() => {
			this.initView('select-core');
			this.selectCoreView.main = this;
			this.selectCoreView.requestErrorHandler = error => {
				return this.requestErrorHandler(error);
			};

			return this.selectCoreView.show(callback);
		});
	},

	// Show available build targets list
	selectBuildTarget(callback) {
		return this.loginRequired(() => {
			this.initView('select-build-target');
			this.selectBuildTargetView.main = this;
			this.selectBuildTargetView.requestErrorHandler = error => {
				return this.requestErrorHandler(error);
			};

			return this.selectBuildTargetView.show(callback);
		});
	},

	// Show rename core dialog
	renameCore() {
		return this.deviceRequired(() => {
			if (this.RenameCoreView == null) {
				this.RenameCoreView = require('./views/rename-core-view');
			}
			this.renameCoreView = new this.RenameCoreView(this.profileManager.currentDevice.name);
			this.renameCoreView.main = this;

			return this.renameCoreView.attach();
		});
	},

	// Remove current core from user's account
	removeCore() {
		return this.deviceRequired(() => {
			const removeButton = `Remove ${this.profileManager.currentDevice.name}`;
			const buttons = {};
			buttons['Cancel'] = function() {};

			buttons[removeButton] = () => {
				this.removePromise = this.spark.removeCore(this.profileManager.currentDevice.id);
				return this.removePromise.then(e => {
					if (!this.removePromise) {
						return;
					}
					this.profileManager.clearCurrentDevice();
					atom.commands.dispatch(this.workspaceElement, `${packageName()}:update-core-status`);
					atom.commands.dispatch(this.workspaceElement, `${packageName()}:update-menu`);

					return this.removePromise = null;
				}
					, e => {
					let message;
					this.removePromise = null;
					this.requestErrorHandler(e);
					if (e.code === 'ENOTFOUND') {
						message = `Error while connecting to ${e.hostname}`;
					} else {
						message = e.info;
					}
					return atom.confirm({
						message: 'Error',
						detailedMessage: message
					});
				});
			};

			return atom.confirm({
				message: 'Removal confirmation',
				detailedMessage: `Do you really want to remove ${this.profileManager.currentDevice.name}?`,
				buttons
			});
		});
	},

	// Show core claiming dialog
	claimCore() {
		return this.loginRequired(() => {
			this.claimCoreView = null;
			this.initView('claim-core');

			this.claimCoreView.main = this;
			return this.claimCoreView.attach();
		});
	},

	// Identify core via serial
	identifyCore(port=null) {
		return this.loginRequired(() => {
			if (!port) {
				return this.choosePort(`${packageName()}:identify-device`);
			} else {
				if (this.SerialHelper == null) {
					this.SerialHelper = require('./utils/serial-helper');
				}
				const promise = this.SerialHelper.askForCoreID(port);
				return promise.then(coreID => {
					if (this.IdentifyCoreView == null) {
						this.IdentifyCoreView = require('./views/identify-core-view');
					}
					this.identifyCoreView = new this.IdentifyCoreView(coreID);
					return this.identifyCoreView.attach();
				}
					, e => {
					this.statusView.setStatus(e, 'error');
					return this.statusView.clearAfter(5000);
				});
			}
		});
	},

	canCompileNow() {
		return !this.compileCloudPromise;
	},

	// Compile current project in the cloud
	// when updating arguments here, also update the event emitter above
	compileCloud(thenFlash=null, files=null, rootPath=null) {
		return this.loginRequired(() => {
			return this.minBuildTargetRequired(() => {
				let serverLocalFilenameMap;
				if (!this.canCompileNow) {
					return;
				}

				// this method should be refactored into 2
				// one part that determines what to compile (from context)
				// another part that expects the files and everything to compile to be provided
				// currently they are both bundled here which requires some recursive calls
				if (!files && this.isLibrary()) {
					const focus = this.isLibraryExampleInFocus();
					if (focus) {
						this.flashCloudExample(focus, !thenFlash);
						return;
					}
				}

				// Including files
				if (fs == null) {
					fs = require('fs-plus');
				}
				if (path == null) {
					path = require('path');
				}
				if (settings == null) {
					settings = require('./vendor/settings');
				}
				if (utilities == null) {
					utilities = require('./vendor/utilities');
				}
				if (_s == null) {
					_s = require('underscore.string');
				}
				if (compilationContext == null) {
					compilationContext = require('./contexts/compilation');
				}

				// if the files have been specified explicitly, assume project etc.. has already been checked for
				if (rootPath == null) {
					rootPath = this.projectRequired(() => this.getProjectDir());
				}
				if (files == null) {
					files = this.processDirIncludes(rootPath);
				}
				[files, serverLocalFilenameMap] = compilationContext.mapLocalToServerFilenames(files, rootPath);

				if (files.length === 0) {
					atom.notifications.addWarning('No .ino/.cpp file to compile');
					return;
				}

				if (atom.config.get(`${packageName()}.saveAllBeforeCompile`)) {
					atom.commands.dispatch(this.workspaceElement, 'window:save-all');
				}

				this.profileManager.setLocal('compile-status', { working: true });
				atom.commands.dispatch(this.workspaceElement, `${packageName()}:update-compile-status`);

				let invalidFiles = files.filter(file => path.basename(file).indexOf(' ') > -1);
				if (invalidFiles.length) {
					invalidFiles = invalidFiles.reduce((acc, value) => `${acc}\n${value}`);
					atom.notifications.addError(`Following files have spaces in their names:\n\n${invalidFiles}\n\nPlease rename them`);
					this.profileManager.setLocal('compile-status', null);
					atom.commands.dispatch(this.workspaceElement, `${packageName()}:update-compile-status`);
					return;
				}

				process.chdir(rootPath);
				if (libraryManager == null) {
					libraryManager = require('particle-library-manager');
				}
				const filesObject = {};
				for (let server in serverLocalFilenameMap) {
					const local = serverLocalFilenameMap[server];
					filesObject[server] = fs.readFileSync(local);
				}

				const targetPlatformId = this.profileManager.currentTargetPlatform;
				const targetBuild = this.getCurrentBuildTarget();
				const targetPlatformSlug = this.getPlatformSlug(targetPlatformId) + '_' + targetBuild;
				console.info('Compile code', filesObject, targetPlatformId, targetBuild);
				this.compileCloudPromise = this.profileManager.apiClient.compileCode(filesObject, targetPlatformId, targetBuild);
				return this.compileCloudPromise.then(value => {
					const e = value.body;
					if (!e) {
						return;
					}

					if (e.ok) {
						// Download binary
						this.compileCloudPromise = null;

						if (atom.config.get(`${packageName()}.deleteOldFirmwareAfterCompile`)) {
							// Remove old firmwares
							files = fs.listSync(rootPath);
							for (let file of files) {
								if (_s.startsWith(path.basename(file), targetPlatformSlug + '_firmware') && _s.endsWith(file, '.bin')) {
									if (fs.existsSync(file)) {
										fs.unlinkSync(file);
									}
								}
							}
						}

						const filename = targetPlatformSlug + '_firmware_' + (new Date()).getTime() + '.bin';
						this.downloadBinaryPromise = this.spark.downloadBinary(e.binary_url, rootPath + '/' + filename);

						return this.downloadBinaryPromise.then(e => {
							this.profileManager.setLocal('compile-status', { filename });
							atom.commands.dispatch(this.workspaceElement, `${packageName()}:update-compile-status`);
							if (thenFlash) {
								// want to explicitly set the file to flash since we cannot assume it from the current project when compiling a library example
								return this.emitter.emit(`${packageName()}:flash-cloud`, { firmware: filename });
							} else {
								return this.downloadBinaryPromise = null;
							}
						}
							, e => {
							return this.requestErrorHandler(e);
						});
					} else {
						return console.log(e);
					}
				}

					, reason => {
					const e = reason.body;
					console.warn('Compilation failed. Reason:', e);
					if (this.CompileErrorsView == null) {
						this.CompileErrorsView = require('./views/compile-errors-view');
					}
					if (errorParser == null) {
						errorParser = require('gcc-output-parser');
					}
					if (e && e.errors && e.errors.length) {
						const errors = errorParser.parseString(e.errors[0]).filter(message => message.type.indexOf('error') > -1);
						this.mapMessageFilenames(errors, serverLocalFilenameMap, rootPath);

						if (errors.length === 0) {
							this.profileManager.setLocal('compile-status', { error: e.output });
						} else {
							this.profileManager.setLocal('compile-status', { errors });
							atom.commands.dispatch(this.workspaceElement, `${packageName()}:show-compile-errors`);
						}
					} else {
						console.error('Compilation failed with unexpected reason:', reason);
						this.profileManager.setLocal('compile-status', { error: e.output });
					}

					atom.commands.dispatch(this.workspaceElement, `${packageName()}:update-compile-status`);
					return this.compileCloudPromise = null;
				});
			});
		});
	},

	mapMessageFilenames(messages, filenameMap, rootPath) {
		const result = [];
		for (let message of messages) {
			const server = message.filename;
			let local = filenameMap[server] || filenameMap[server.replace('.cpp', '.ino')];
			if (local) {
				local = path.resolve(rootPath, local);
				message.serverFilename = server;
				result.push(message.filename = local);
			} else {
				result.push(undefined);
			}
		}
		return result;
	},

	// Show compile errors list
	showCompileErrors() {
		this.initView('compile-errors');

		this.compileErrorsView.main = this;
		return this.compileErrorsView.show();
	},

	// Flash core via the cloud
	flashCloud(firmware=null) {
		return this.deviceRequired(() => {
			if (fs == null) {
				fs = require('fs-plus');
			}
			if (path == null) {
				path = require('path');
			}
			if (_s == null) {
				_s = require('underscore.string');
			}
			if (utilities == null) {
				utilities = require('./vendor/utilities');
			}
			console.log('flashCloud', firmware);

			const targetPlatformSlug = this.getPlatformSlug(this.profileManager.currentTargetPlatform);

			let files = null;
			let rootPath = null;
			if (firmware) {
				files = [firmware];
			} else {
				if (this.isLibrary()) {
					const focus = this.isLibraryExampleInFocus();
					if (focus) {
						this.flashCloudExample(focus);
						return;
					}
				}

				this.projectRequired(() => {
					rootPath = this.getProjectDir();
					files = fs.listSync(rootPath);
					return files = files.filter(file =>
						(utilities.getFilenameExt(file).toLowerCase() === '.bin') &&
                 (_s.startsWith(path.basename(file), targetPlatformSlug))
					);
				});
			}

			if (!files || (files.length === 0)) {
			// If no firmware file, compile
				return this.emitter.emit(`${packageName()}:compile-cloud`, { thenFlash: true });
			} else if (files.length === 1) {
			// If one firmware file, flash
				firmware = files[0];
				const flashDevice = () => {
					if (rootPath) {
						process.chdir(rootPath);
						firmware = path.relative(rootPath, firmware);
					}

					this.statusView.setStatus('Flashing via the cloud...');

					this.flashCorePromise = this.spark.flashCore(this.profileManager.currentDevice.id, [firmware]);
					return this.flashCorePromise.then(e => {
						if (e.ok === false) {
							let error = 'Unknown error';
							if (e.errors != null && e.errors[0].error) {
								error = e.errors != null && e.errors[0].error;
							}
							this.statusView.setStatus(error, 'error');
							this.statusView.clearAfter(5000);
						} else {
							this.statusView.setStatus(e.status + '...');
							this.statusView.clearAfter(5000);

							if (atom.config.get(`${packageName()}.deleteFirmwareAfterFlash`)) {
								if (fs.existsSync(firmware)) {
									fs.unlink(firmware);
								}
							}
						}

						return this.flashCorePromise = null;
					}
						, e => {
						this.requestErrorHandler(e);
						if (e.code === 'ECONNRESET') {
							this.statusView.setStatus('Device seems to be offline', 'error');
						} else {
							this.statusView.setStatus(e.message, 'error');
						}
						this.statusView.clearAfter(5000);
						return this.flashCorePromise = null;
					});
				};

				if (this.profileManager.currentDevice.platformId === 10) {
					return atom.confirm({
						message: 'Flashing over cellular',
						detailedMessage: `You're trying to flash your app to ${this.profileManager.currentDevice.name} over cellular. This will use at least a few KB from your \
data plan. Instead it's recommended to flash \
it via USB.`,
						buttons: {
							'Cancel'() {},
							'Flash OTA anyway': () => {
								return flashDevice();
							}
						}
					});
				} else {
					return flashDevice();
				}
			} else {
			// If multiple firmware files, show select
				this.initView('select-firmware');

				files.reverse();
				this.selectFirmwareView.setItems(files);
				return this.selectFirmwareView.show();
			}
		});
	},

	isLibraryExampleSync(file) {
		// todo - move to lib manager
		if (path == null) {
			path = require('path');
		}
		if (fs == null) {
			fs = require('fs');
		}
		try {
			const stat = fs.statSync(file);
			if (stat.isFile()) {
				file = path.dirname(file);
			}
			const examples = path.dirname(file);
			const libroot = path.dirname(examples);
			const split = examples.split(path.sep);
			const properties = path.join(libroot, 'library.properties');
			const propertiesExists = fs.existsSync(properties);
			const examplesDirectory = split[split.length-1];
			return propertiesExists && examples && (examplesDirectory==='examples');
		} catch (ex) {
			return false;
		}
	},

	isLibraryExample(file) {
		if (libraryManager == null) {
			libraryManager = require('particle-library-manager');
		}
		return libraryManager.isLibraryExample(file);
	},

	flashCloudExample(file, compileOnly) {
		if (libraryManager == null) {
			libraryManager = require('particle-library-manager');
		}
		return libraryManager.isLibraryExample(path.basename(file), path.dirname(file))
			.then(example => {
				if (example) {
					console.log('example is', example);
					const files = {};
					return example.buildFiles(files)
						.then(() => {
							console.log('compiling example files', files);
							return this.emitter.emit(`${packageName()}:compile-cloud`, { thenFlash: !compileOnly, files: files.map, rootPath: files.basePath });
						});
				}
			});
	},

	flashCloudFile(event) {
		return this.deviceRequired(() => {
			return this.flashCloud(event.target.dataset.path);
		});
	},

	flashCloudExampleFile(event) {
		return this.deviceRequired(() => {
			const file = event.target.dataset.path;
			return this.emitter.emit(`${packageName()}:flash-cloud-example`, { file });
		});
	},

	// Show serial monitor panel
	showSerialMonitor() {
		if (this.SerialMonitorView == null) {
			this.SerialMonitorView = require('./views/serial-monitor-view');
		}
		this.serialMonitorView = new this.SerialMonitorView(this);

		return atom.workspace.open(this.serialMonitorView);
	},

	// Set up core's WiFi
	setupWifi(port=null) {
		return this.loginRequired(() => {
			if (!port) {
				return this.choosePort(`${packageName()}:setup-wifi`);
			} else {
				this.initView('select-wifi');
				this.selectWifiView.port = port;
				return this.selectWifiView.show();
			}
		});
	},

	enterWifiCredentials(port, ssid=null, security=null) {
		return this.loginRequired(() => {
			if (!port) {
				return;
			}

			this.wifiCredentialsView = null;
			this.initView('wifi-credentials');
			this.wifiCredentialsView.port = port;
			return this.wifiCredentialsView.show(ssid, security);
		});
	},

	tryFlashUsb() {
		return this.projectRequired(() => {
			atom.notifications.addWarning('Flashing via USB from Particle Dev has not yet been implemented');
			if (!atom.commands.registeredCommands[`${packageName()}-dfu-util:flash-usb`]) {
			// TODO: Ask for installation
			} else {
				return atom.commands.dispatch(this.workspaceElement, `${packageName()}-dfu-util:flash-usb`);
			}
		});
	},

	analyticsContext() {
		return this.analytics.commandContext(this.profileManager, this.profileManager.apiClient);
	},

	runParticleCommand(site, command) {
		const contextPromise = this.analyticsContext();
		return contextPromise.then(context => site.run(command, context));
	},

	_registerCommands() {
		const commands = {};
		commands[`${packageName()}:login`] = () => this.login();
		commands[`${packageName()}:logout`] = () => this.logout();
		commands[`${packageName()}:select-device`] = () => this.selectCore();
		commands[`${packageName()}:rename-device`] = () => this.renameCore();
		commands[`${packageName()}:remove-device`] = () => this.removeCore();
		commands[`${packageName()}:claim-device`] = () => this.claimCore();
		commands[`${packageName()}:try-flash-usb`] = () => this.tryFlashUsb();
		commands[`${packageName()}:update-menu`] = () => this.MenuManager.update();
		commands[`${packageName()}:show-compile-errors`] = () => this.showCompileErrors();
		commands[`${packageName()}:show-serial-monitor`] = () => this.showSerialMonitor();
		commands[`${packageName()}:identify-device`] = () => this.identifyCore();
		commands[`${packageName()}:compile-cloud`] = () => this.compileCloud();
		commands[`${packageName()}:flash-cloud`] = () => this.flashCloud();
		commands[`${packageName()}:flash-cloud-file`] = event => this.flashCloudFile(event);
		commands[`${packageName()}:flash-cloud-example-file`] = event => this.flashCloudExampleFile(event);
		commands[`${packageName()}:setup-wifi`] = () => this.setupWifi();
		commands[`${packageName()}:enter-wifi-credentials`] = () => this.enterWifiCredentials();
		commands[`${packageName()}:select-build-target`] = () => this.selectBuildTarget();
		commands[`${packageName()}:update-core-status`] = () => this.updateToolbarButtons();
		return this.disposables.add(atom.commands.add('atom-workspace', commands));
	},

	_registerEventListeners() {
		this.emitter.on(`${packageName()}:identify-device`, event => {
			return this.identifyCore(event.port);
		});

		this.emitter.on(`${packageName()}:select-device`, event => {
			return this.selectCore(event.callback);
		});

		this.emitter.on(`${packageName()}:compile-cloud`, event => {
			return this.compileCloud(event.thenFlash, event.files, event.rootPath);
		});

		this.emitter.on(`${packageName()}:flash-cloud`, event => {
			return this.flashCloud(event.firmware);
		});

		this.emitter.on(`${packageName()}:flash-cloud-example`, event => {
			return this.flashCloudExample(event.file);
		});

		this.emitter.on(`${packageName()}:setup-wifi`, event => {
			return this.setupWifi(event.port);
		});

		this.emitter.on(`${packageName()}:enter-wifi-credentials`, event => {
			return this.enterWifiCredentials(event.port, event.ssid, event.security);
		});

		return this.emitter.on('update-login-status', () => this.updateToolbarButtons());
	},

	_registerUrlOpener() {
		url = require('url');
		return atom.workspace.addOpener(uriToOpen => {
			let pathname, protocol;
			try {
				let host;
				({ protocol, host, pathname } = url.parse(uriToOpen));
			} catch (error) {
				return;
			}

			if (protocol !== `${packageName()}:`) {
				return;
			}

			try {
				return this.initView(pathname.substr(1));
			} catch (error1) {
				return;
			}
		});
	},

	_registerContextMenus() {
		const self = this;
		const flashExampleMenuItem = [{
			label: 'Flash Example OTA',
			command: `${packageName()}:flash-cloud-example-file`,
			shouldDisplay: event => this.isLibraryExampleSync(event.target.dataset.path),
			created(event) {
				return this.enabled = self.canCompileNow();
			}
		}];

		const contextMenus = {
			'.tree-view.full-menu [is="tree-view-file"] [data-name$=".cpp"]':flashExampleMenuItem,
			'.tree-view.full-menu [is="tree-view-file"] [data-name$=".ino"]':flashExampleMenuItem,
			// when matching the directory, the item is also propagated to all child elements of that directory regardless
			// of their extension, so for now compiling an example is done only from the files themselves
			//      '.tree-view.full-menu [is="tree-view-directory"]':flashExampleMenuItem
		};

		return this.contextMenus.add(atom.contextMenu.add(contextMenus));
	},

	_onProfileChanged() {
		this.accessToken = this.profileManager.accessToken;
		this.updateToolbarButtons();
		this.MenuManager.update();
		return atom.commands.dispatch(this.workspaceElement, `${packageName()}:update-login-status`);
	}
};
