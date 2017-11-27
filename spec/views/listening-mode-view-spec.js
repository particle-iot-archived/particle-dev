'use babel';
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import SettingsHelper from '../../lib/utils/settings-helper';
import SerialHelper from '../../lib/utils/serial-helper';
import packageName from '../../lib/utils/package-helper';
import ListeningModeView from '../../lib/views/listening-mode-view';
import 'serialport';

let defaultExport = {};
describe('Listening Mode View', function() {
  let activationPromise = null;
  let main = null;
  let listeningModeView = null;
  let originalProfile = null;
  let workspaceElement = null;

  beforeEach(function() {
    workspaceElement = atom.views.getView(atom.workspace);
    activationPromise = atom.packages.activatePackage(packageName()).then(({mainModule}) => main = mainModule);

    originalProfile = SettingsHelper.getProfile();
    // For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile('test');

    SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');

    // Mock serial
    require.cache[require.resolve('serialport')].defaultExport = require('particle-dev-spec-stubs').serialportNoPorts;

    return waitsForPromise(() => activationPromise);
  });

  afterEach(function() {
    SettingsHelper.clearCredentials();
    return SettingsHelper.setProfile(originalProfile);
  });

  return describe('', function() {
    it('tests hiding and showing', function() {
      listeningModeView = new ListeningModeView();

      // Test core:cancel
      spyOn(listeningModeView.panel, 'show').andCallThrough();
      listeningModeView.show();
      expect(listeningModeView.panel.show).toHaveBeenCalled();

      spyOn(listeningModeView, 'hide').andCallThrough();
      atom.commands.dispatch(workspaceElement, 'core:cancel');
      expect(listeningModeView.hide).toHaveBeenCalled();

      // listeningModeView.show()
      // listeningModeView.hide.reset()
      // atom.commands.dispatch workspaceElement, 'core:close'
      // expect(listeningModeView.hide).toHaveBeenCalled()

      listeningModeView.show();
      listeningModeView.hide.reset();
      listeningModeView.find('button').click();
      expect(listeningModeView.hide).toHaveBeenCalled();

      jasmine.unspy(listeningModeView.panel, 'show');
      jasmine.unspy(listeningModeView, 'hide');
      return listeningModeView.cancel();
    });

    return it('tests interval for dialog dismissal', function() {
      jasmine.Clock.useMock();
      listeningModeView = new ListeningModeView();
      spyOn(SerialHelper, 'listPorts');

      listeningModeView.show();
      expect(SerialHelper.listPorts).not.toHaveBeenCalled();
      jasmine.Clock.tick(1001);
      expect(SerialHelper.listPorts).toHaveBeenCalled();

      jasmine.unspy(SerialHelper, 'listPorts');
      return listeningModeView.cancel();
    });
  });
});
export default defaultExport;
