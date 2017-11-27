'use babel';
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let jQuery;
import SettingsHelper from '../../lib/utils/settings-helper';
import packageName from '../../lib/utils/package-helper';
const $ = (jQuery = require('jquery'));

let defaultExport = {};
describe('Serial Monitor View', function() {
  let activationPromise = null;
  let originalProfile = null;
  let main = null;
  let workspaceElement = null;
  let serialMonitorView = null;

  const initView = function() {
    main.serialMonitorView = null;
    main.initView('serial-monitor');
    return serialMonitorView = main.serialMonitorView;
  };

  beforeEach(function() {
    workspaceElement = atom.views.getView(atom.workspace);

    // Mock serial
    require.cache[require.resolve('serialport')].defaultExport = require('particle-dev-spec-stubs').serialportMultiplePorts;

    activationPromise = atom.packages.activatePackage(packageName()).then(function({mainModule}) {
      main = mainModule;
      return initView();
    });

    originalProfile = SettingsHelper.getProfile();
    // For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile('test');

    return waitsForPromise(() => activationPromise);
  });

  afterEach(() => SettingsHelper.setProfile(originalProfile));

  return describe('', function() {
    beforeEach(function() {});

    afterEach(function() {});

    it('checks listing ports and baudrates', function() {
      // Test ports
      require.cache[require.resolve('serialport')].defaultExport = require('particle-dev-spec-stubs').serialportSuccess;
      serialMonitorView.nullifySerialport();

      serialMonitorView.refreshSerialPorts();
      let options = serialMonitorView.portsSelect.find('option');
      expect(options.length).toEqual(1);
      expect(options.text()).toEqual('/dev/cu.usbmodemfa1234');
      expect(options.val()).toEqual('/dev/cu.usbmodemfa1234');

      require.cache[require.resolve('serialport')].defaultExport = require('particle-dev-spec-stubs').serialportMultiplePorts;
      serialMonitorView.nullifySerialport();
      serialMonitorView.find('#refresh-ports-button').click();

      options = serialMonitorView.portsSelect.find('option');

      expect(options.length).toEqual(2);
      expect($(options[0]).text()).toEqual('/dev/cu.usbmodemfa1234');
      expect($(options[0]).val()).toEqual('/dev/cu.usbmodemfa1234');

      expect($(options[1]).text()).toEqual('/dev/cu.usbmodemfab1234');
      expect($(options[1]).val()).toEqual('/dev/cu.usbmodemfab1234');

      // Test baudrates
      options = serialMonitorView.baudratesSelect.find('option');
      expect(options.length).toEqual(12);

      let idx = 0;
      return (() => {
        const result = [];
        for (let baudrate of [300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200]) {
          expect($(options[idx]).text()).toEqual(baudrate.toString());
          expect($(options[idx]).val()).toEqual(baudrate.toString());
          result.push(idx++);
        }
        return result;
      })();
    });

      // serialMonitorView.close()

    it('checks blocking UI on connection', function() {
      expect(serialMonitorView.portsSelect.attr('disabled')).toBeUndefined();
      expect(serialMonitorView.refreshPortsButton.attr('disabled')).toBeUndefined();
      expect(serialMonitorView.baudratesSelect.attr('disabled')).toBeUndefined();
      expect(serialMonitorView.connectButton.text()).toEqual('Connect');
      expect(serialMonitorView.input.enabled).toBe(false);

      serialMonitorView.connectButton.click();

      expect(serialMonitorView.portsSelect.attr('disabled')).toEqual('disabled');
      expect(serialMonitorView.refreshPortsButton.attr('disabled')).toEqual('disabled');
      expect(serialMonitorView.baudratesSelect.attr('disabled')).toEqual('disabled');
      expect(serialMonitorView.connectButton.text()).toEqual('Disconnect');
      expect(serialMonitorView.input.enabled).toBe(true);

      serialMonitorView.connectButton.click();

      expect(serialMonitorView.portsSelect.attr('disabled')).toBeUndefined();
      expect(serialMonitorView.refreshPortsButton.attr('disabled')).toBeUndefined();
      expect(serialMonitorView.baudratesSelect.attr('disabled')).toBeUndefined();
      expect(serialMonitorView.connectButton.text()).toEqual('Connect');
      expect(serialMonitorView.input.enabled).toBe(false);

      serialMonitorView.connectButton.click();

      // Test disconnecting on error
      expect(serialMonitorView.connectButton.text()).toEqual('Disconnect');
      spyOn(console, 'error');
      serialMonitorView.port.emit('error');

      expect(serialMonitorView.connectButton.text()).toEqual('Connect');
      expect(console.error).toHaveBeenCalled();

      return jasmine.unspy(console, 'error');
    });
      // serialMonitorView.close()

    it('checks serial communication', function() {
      serialMonitorView.connectButton.click();

      // Test receiving data
      serialMonitorView.port.emit('data', 'foo');
      expect(serialMonitorView.output.text()).toEqual('foo');

      // Test sending data
      spyOn(serialMonitorView.port, 'write');
      spyOn(serialMonitorView, 'isPortOpen').andReturn(true);

      serialMonitorView.input.editor.setText('foo');
      atom.commands.dispatch(serialMonitorView.input.editor.element, 'core:confirm');

      expect(serialMonitorView.port.write).toHaveBeenCalled();

      jasmine.unspy(serialMonitorView.port, 'write');
      return jasmine.unspy(serialMonitorView, 'isPortOpen');
    });
      // serialMonitorView.close()

    return it('checks default port and baudrate', function() {
      SettingsHelper.set('serial_port', null);
      SettingsHelper.set('serial_baudrate', null);
      initView();

      expect(serialMonitorView.portsSelect.val()).toEqual('/dev/cu.usbmodemfa1234');
      expect(serialMonitorView.baudratesSelect.val()).toEqual('9600');

      SettingsHelper.set('serial_port', '/dev/cu.usbmodemfab1234');
      SettingsHelper.set('serial_baudrate', 115200);
      initView();

      expect(serialMonitorView.portsSelect.val()).toEqual('/dev/cu.usbmodemfab1234');
      return expect(serialMonitorView.baudratesSelect.val()).toEqual('115200');
    });
  });
});
export default defaultExport;
