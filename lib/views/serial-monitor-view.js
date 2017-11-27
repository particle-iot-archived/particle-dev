'use babel';

import { View } from 'atom-space-pen-views';
import { CompositeDisposable } from 'atom';
import { MiniEditorView } from 'particle-dev-views';
import { packageName } from '../utils/package-helper';

let $$ = null;
let serialport = null;

export default class SerialMonitorView extends View {
	static content() {
		this.div({ id: 'serial-monitor', class: `panel ${packageName()}` }, () => {
			this.div({ class: 'panel-heading' }, () => {
				this.select({ outlet: 'portsSelect', change: 'portSelected' }, () => {
					this.option({ value: '' }, 'No port selected');
				});
				this.button({ class: 'btn icon-sync', id: 'refresh-ports-button', outlet: 'refreshPortsButton', click: 'refreshSerialPorts' }, '');
				this.span('@');
				this.select({ outlet: 'baudratesSelect', change: 'baudrateSelected' });
				this.button({ class: 'btn', outlet: 'connectButton', click: 'toggleConnect' }, 'Connect');
				this.button({ class: 'btn pull-right', click: 'clearOutput' }, 'Clear');
			});
			this.div({ class: 'panel-body', outlet: 'variables' }, () => {
				this.pre({ outlet: 'output' });
				this.subview('input', new MiniEditorView('Enter string to send'));
			});
		});
	}

	constructor(main) {
		super();
		this.main = main;
		this.setup();
	}

	initialize(serializeState) {}

	setup() {
		({ $$ } = require('atom-space-pen-views'));

		this.disposables = new CompositeDisposable;

		this.currentPort = null;
		this.refreshSerialPorts();

		this.currentBaudrate = this.main.profileManager.get('serial_baudrate');
		if (this.currentBaudrate == null) {
			this.currentBaudrate = 9600;
		}
		this.currentBaudrate = parseInt(this.currentBaudrate);

		this.baudratesList = [300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200];
		for (var baudrate of this.baudratesList) {
			const option = $$(function renderOption() {
				this.option({ value:baudrate }, baudrate);
			});
			if (baudrate === this.currentBaudrate) {
				option.attr('selected', 'selected');
			}
			this.baudratesSelect.append(option);
		}

		this.port = null;

		this.disposables.add(atom.commands.add(this.input.editor.element, {
			'core:confirm': () => {
				if (this.isPortOpen()) {
					this.port.write(this.input.editor.getText() + '\n');
					this.input.editor.setText('');
				}
			}
		}));
		this.input.setEnabled(false);
	}

	destroy() {
		return (this.disposables != null ? this.disposables.dispose() : undefined);
	}

	serialize() {}

	getTitle() {
		return 'Serial monitor';
	}

	getUri() {
		return `${packageName()}://editor/serial-monitor`;
	}

	getDefaultLocation() {
		return 'bottom';
	}

	close() {
		const pane = atom.workspace.paneForUri(this.getUri());
		return (pane != null ? pane.destroy() : undefined);
	}

	escapeHtml(unsafe) {
		return unsafe
			.replace(/&/g, '&amp;')
			.replace(/</g, '&lt;')
			.replace(/>/g, '&gt;')
			.replace(/"/g, '&quot;')
			.replace(/'/g, '&#039;');
	}

	appendText(text, appendNewline) {
		if (appendNewline == null) {
			appendNewline = true;
		}
		const at_bottom = ((this.output.scrollTop() + this.output.innerHeight() + 10) > this.output[0].scrollHeight);

		text = this.escapeHtml(text);
		text = text.replace('\r', '');
		if (appendNewline) {
			text += '\n';
		}
		this.output.html(this.output.html() + text);

		if (at_bottom) {
			this.output.scrollTop(this.output[0].scrollHeight);
		}
	}

	refreshSerialPorts() {
		if (serialport == null) {
			serialport = require('serialport');
		}
		return serialport.list((err, ports) => {
			this.portsSelect.find('>').remove();
			this.currentPort = this.main.profileManager.get('serial_port');
			for (var port of ports) {
				const option = $$(function renderOption() {
					this.option({ value: port.comName }, port.comName);
				});
				if (this.currentPort === port.comName) {
					option.attr('selected', 'selected');
				}
				this.portsSelect.append(option);
			}

			if (ports.length > 0) {
				if (this.currentPort == null) {
					this.currentPort = ports[0].comName;
				}
				return this.main.profileManager.set('serial_port', this.currentPort);
			}
		});
	}

	portSelected() {
		this.currentPort = this.portsSelect.val();
		return this.main.profileManager.set('serial_port', this.currentPort);
	}

	baudrateSelected() {
		this.currentBaudrate = parseInt(this.baudratesSelect.val());
		return this.main.profileManager.set('serial_baudrate', this.currentBaudrate);
	}

	toggleConnect() {
		if (this.portsSelect.attr('disabled')) {
			return this.disconnect();
		} else {
			return this.connect();
		}
	}

	isPortOpen() {
		return (this.port != null ? this.port.fd : undefined) && (parseInt(this.port.fd) >= 0);
	}

	connect() {
		this.portsSelect.attr('disabled', 'disabled');
		this.refreshPortsButton.attr('disabled', 'disabled');
		this.baudratesSelect.attr('disabled', 'disabled');
		this.connectButton.text('Disconnect');
		this.input.setEnabled(true);

		this.port = new serialport.SerialPort(this.currentPort, {
			baudrate: this.currentBaudrate,
			autoOpen: false
		});

		if (this.port != null) {
			this.port.on('close', () => {
				return this.disconnect();
			});
		}

		if (this.port != null) {
			this.port.on('error', e => {
				console.error(e);
				return this.disconnect();
			});
		}

		if (this.port != null) {
			this.port.on('data', data => {
				this.appendText(data.toString(), false);
			});
		}

		if (this.port != null) {
			this.port.open();
		}
		this.input.editor.element.focus();
	}

	disconnect() {
		this.portsSelect.removeAttr('disabled');
		this.refreshPortsButton.removeAttr('disabled');
		this.baudratesSelect.removeAttr('disabled');
		this.connectButton.text('Connect');
		this.input.setEnabled(false);

		if (this.isPortOpen()) {
			return this.port.close();
		}
	}

	clearOutput() {
		this.output.html('');
	}

	// Method used only in tests
	nullifySerialport() {
		serialport = null;
	}
}
