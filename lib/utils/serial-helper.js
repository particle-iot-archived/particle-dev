'use babel';

import whenjs from 'when';
import pipeline from 'when/pipeline';
let serialport = null;
import utilities from '../vendor/utilities';
import SerialBoredParser from '../vendor/SerialBoredParser';

// Decaffeinated CoffeeScript port of SerialCommand.js functions from spark-cli
export default {
	listPorts() {
		// Return promise with core's serial ports
		serialport = require('serialport');
		const dfd = whenjs.defer();

		const cores = [];
		serialport.list(function(err, ports) {
			let port;
			if (ports) {
				for (port of ports) {
					if ((port.manufacturer && (port.manufacturer.indexOf('Particle') >= 0)) ||
              (port.pnpId && (port.pnpId.indexOf('Spark_Core') >= 0))) {
						cores.push(port);
					}
				}
			}

			if (!cores.length) {
				for (port of ports) {
					if (port.comName.indexOf('/dev/ttyACM') === 0) {
						cores.push(port);
					} else if (port.comName.indexOf('/dev/cuaU') === 0) {
						cores.push(port);
					}
				}
			}

			return dfd.resolve(cores);
		});
		return dfd.promise;
	},

	askForCoreID(comPort) {
		// Return promise with core's ID
		let serialPort;
		serialport = require('serialport');
		const failDelay = 5000;
		const dfd = whenjs.defer();

		try {
			const boredDelay = 100;
			let boredTimer = [];
			const chunks = [];

			serialPort = new serialport.SerialPort(comPort, {
				baudrate: 9600,
				parser: SerialBoredParser.MakeParser(250),
				autoOpen: false
			});

			const whenBored = function() {
				let data = chunks.join('');
				const prefix = 'Your device id is ';
				if (data.indexOf(prefix) >= 0) {
					data = data.replace(prefix, '').trim();
					return dfd.resolve(data);
				}
			};

			const failTimer = setTimeout(() => dfd.reject('Serial timed out')
				, failDelay);

			serialPort.on('data', function(data) {
				clearTimeout(failTimer);
				clearTimeout(boredTimer);

				chunks.push(data);
				boredTimer = setTimeout(whenBored, boredDelay);
			});

			serialPort.open(function(err) {
				if (err) {
					dfd.reject('Serial problems, please reconnect the core.');
				} else {
					serialPort.write('i');
				}
			});

			whenjs(dfd.promise).ensure(function() {
				serialPort.removeAllListeners('open');
				serialPort.removeAllListeners('data');
			});

		} catch (error) {
			dfd.reject('Serial errors');
			console.error(error);
		}

		return whenjs(dfd.promise).ensure(() => {
			if (serialPort) {
				serialPort.close();
			}
		});
	},

	serialPromptDfd(serialPort, prompt, answer, timeout, alwaysResolve) {
		// Return promise of serial prompt and answer
		serialport = require('serialport');
		const dfd = whenjs.defer();
		let failTimer = true;
		const showTraffic = true;

		const writeAndDrain = (data, callback) =>
			serialPort.write(data, () => serialPort.drain(callback))
    ;

		if (timeout) {
			failTimer = setTimeout(function() {
				if (showTraffic) {
					console.log(`Timed out on ${prompt}`);
				}
				if (alwaysResolve) {
					dfd.resolve(null);
				} else {
					dfd.reject('Serial prompt timed out - Please try restarting your core');
				}
			}
				, timeout);
		}

		if (prompt) {
			const onMessage = function(data) {
				data = data.toString();

				if (showTraffic) {
					console.log(`Serial said: ${data}`);
				}
				if (data && (data.indexOf(prompt) >= 0)) {
					if (answer) {
						serialPort.flush(function() {});

						writeAndDrain(answer, function() {
							if (showTraffic) {
								console.log(`I said: ${answer}`);
							}
							dfd.resolve(true);
						});
					} else {
						dfd.resolve(true);
					}
				}
			};

			serialPort.on('data', onMessage);

			whenjs(dfd.promise).ensure(function() {
				clearTimeout(failTimer);
				serialPort.removeListener('data', onMessage);
			});
		} else if (answer) {
			clearTimeout(failTimer);

			if (showTraffic) {
				console.log(`I said: ${answer}`);
			}

			writeAndDrain(answer, () => dfd.resolve(true));
		}

		return dfd.promise;
	},

	serialWifiConfig(comPort, ssid, password, securityType, failDelay) {
		// Return prmise of setting WiFi credentials
		serialport = require('serialport');
		const dfd = whenjs.defer();

		const serialPort = new serialport.SerialPort(comPort, {
			baudrate: 9600,
			parser: SerialBoredParser.MakeParser(250),
			autoOpen: false
		});

		serialPort.on('error', () => dfd.reject('Serial error'));

		serialPort.open(() => {
			const configDone = pipeline([
				() => {
					return this.serialPromptDfd(serialPort, null, 'w', 5000, true);
				}
				, result => {
					if (!result) {
						return this.serialPromptDfd(serialPort, null, 'w', 5000, true);
					} else {
						return whenjs.resolve();
					}
				}
				, () => {
					return this.serialPromptDfd(serialPort, 'SSID:', ssid + '\n', 5000, false);
				}
				, () => {
					const prompt = 'Security 0=unsecured, 1=WEP, 2=WPA, 3=WPA2:';
					return this.serialPromptDfd(serialPort, prompt, securityType + '\n', 1500, true);
				}
				, result => {
					let passPrompt = 'Password:';
					if (!result) {
						passPrompt = null;
					}

					if (!passPrompt || !password || (password === '')) {
						return whenjs.resolve();
					}

					return this.serialPromptDfd(serialPort, passPrompt, password + '\n', 5000);
				}
				, () => {
					return this.serialPromptDfd(serialPort, 'Spark <3 you!', null, 15000);
				}
			]);
			utilities.pipeDeferred(configDone, dfd);

			return whenjs(dfd.promise).ensure(() => serialPort.close());
		});

		return dfd.promise;
	}
};
