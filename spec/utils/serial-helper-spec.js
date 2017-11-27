'use babel';
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import 'serialport';
let defaultExport = {};
require.cache[require.resolve('serialport')].defaultExport = require('particle-dev-spec-stubs').serialportSuccess;
const SerialHelper = require('../../lib/utils/serial-helper');

describe('Serial helper tests', function() {
  it('tests listing ports', function() {
    const promise = SerialHelper.listPorts();

    waitsFor(() => promise.inspect().state === 'fulfilled');

    return runs(function() {
      const status = promise.inspect();
      return expect(status.value.length).toBe(1);
    });
  });

  it('tests listing multiple ports', function() {
    require.cache[require.resolve('serialport')].defaultExport = require('particle-dev-spec-stubs').serialportMultiplePorts;
    const promise = SerialHelper.listPorts();

    waitsFor(() => promise.inspect().state === 'fulfilled');

    return runs(function() {
      const status = promise.inspect();
      return expect(status.value.length).toBe(2);
    });
  });

  it('tests listing no ports', function() {
    require.cache[require.resolve('serialport')].defaultExport = require('particle-dev-spec-stubs').serialportNoPorts;
    const promise = SerialHelper.listPorts();

    waitsFor(() => promise.inspect().state === 'fulfilled');

    return runs(function() {
      const status = promise.inspect();
      return expect(status.value.length).toBe(0);
    });
  });

  it('tests retreiving core ID', function() {
    const promise = SerialHelper.askForCoreID('foo');

    waitsFor(() => promise.inspect().state === 'fulfilled');

    return runs(function() {
      const status = promise.inspect();
      return expect(status.value).toBe('0123456789abcdef0123456789abcdef');
    });
  });

  return it('tests saving WiFi credentials', function() {
    const promise = SerialHelper.serialWifiConfig('foo', 'ssid', 'pass', 3);

    waitsFor(() => promise.inspect().state === 'fulfilled');

    return runs(function() {
      let status;
      return status = promise.inspect();
    });
  });
});
export default defaultExport;
