'use babel';
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import SettingsHelper from '../../lib/utils/settings-helper';
import SelectPortView from '../../lib/views/select-port-view';
import packageName from '../../lib/utils/package-helper';

let defaultExport = {};
describe('Select Port View', function() {
  let activationPromise = null;
  let main = null;
  let selectPortView = null;
  let originalProfile = null;
  let workspaceElement = null;

  beforeEach(function() {
    workspaceElement = atom.views.getView(atom.workspace);
    activationPromise = atom.packages.activatePackage(packageName()).then(function({mainModule}) {
      main = mainModule;
      return selectPortView = new SelectPortView;
    });

    originalProfile = SettingsHelper.getProfile();
    // For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile('test');

    // Mock serial
    require.cache[require.resolve('serialport')].defaultExport = require('particle-dev-spec-stubs').serialportMultiplePorts;

    return waitsForPromise(() => activationPromise);
  });

  afterEach(() => SettingsHelper.setProfile(originalProfile));

  return describe('', () =>
    it('tests loading items', function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      selectPortView.show();

      waitsFor(() => !selectPortView.listPortsPromise);

      return runs(function() {
        const devices = selectPortView.find('ol.list-group li');
        expect(devices.length).toEqual(2);

        expect(devices.eq(0).find('.primary-line').text()).toEqual('8D7028785754');
        expect(devices.eq(1).find('.primary-line').text()).toEqual('8D7028785755');

        expect(devices.eq(0).find('.secondary-line').text()).toEqual('/dev/cu.usbmodemfa1234');
        expect(devices.eq(1).find('.secondary-line').text()).toEqual('/dev/cu.usbmodemfab1234');

        selectPortView.hide();
        return SettingsHelper.clearCredentials();
      });
    })
  );
});
export default defaultExport;
