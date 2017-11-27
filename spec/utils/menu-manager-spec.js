'use babel';
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import MenuManager from '../../lib/utils/menu-manager';
import SettingsHelper from '../../lib/utils/settings-helper';
import packageName from '../../lib/utils/package-helper';

describe('MenuManager tests', function() {
  let activationPromise = null;
  let originalProfile = null;
  let workspaceElement = null;

  beforeEach(function() {
    originalProfile = SettingsHelper.getProfile();
    // For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile('test');

    workspaceElement = atom.views.getView(atom.workspace);
    return activationPromise = atom.packages.activatePackage(packageName());
  });

  afterEach(() => SettingsHelper.setProfile(originalProfile));

  it('checks menu for logged out user', function() {
    waitsForPromise(() => activationPromise);

    return runs(function() {
      const ideMenu = MenuManager.getMenu();

      expect(ideMenu.submenu.length).toBe(3);
      let idx = 0;

      expect(ideMenu.submenu[idx].label).toBe('Log in to Particle Cloud...');
      expect(ideMenu.submenu[idx++].command).toBe(`${packageName()}:login`);

      expect(ideMenu.submenu[idx++].type).toBe('separator');

      expect(ideMenu.submenu[idx].label).toBe('Show serial monitor');
      return expect(ideMenu.submenu[idx++].command).toBe(`${packageName()}:show-serial-monitor`);
    });
  });


  it('checks menu for logged in user', function() {
    waitsForPromise(() => activationPromise);

    return runs(function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');

      // Refresh UI
      atom.commands.dispatch(workspaceElement, `${packageName()}:update-menu`);

      const ideMenu = MenuManager.getMenu();

      expect(ideMenu.submenu.length).toBe(11);
      let idx = 0;

      expect(ideMenu.submenu[idx].label).toBe('Log out foo@bar.baz');
      expect(ideMenu.submenu[idx++].command).toBe(`${packageName()}:logout`);

      expect(ideMenu.submenu[idx++].type).toBe('separator');

      expect(ideMenu.submenu[idx].label).toBe('Select device...');
      expect(ideMenu.submenu[idx++].command).toBe(`${packageName()}:select-device`);

      expect(ideMenu.submenu[idx++].type).toBe('separator');

      expect(ideMenu.submenu[idx].label).toBe('Claim device...');
      expect(ideMenu.submenu[idx++].command).toBe(`${packageName()}:claim-device`);

      expect(ideMenu.submenu[idx].label).toBe('Identify device...');
      expect(ideMenu.submenu[idx++].command).toBe(`${packageName()}:identify-device`);

      expect(ideMenu.submenu[idx].label).toBe('Setup device\'s WiFi...');
      expect(ideMenu.submenu[idx++].command).toBe(`${packageName()}:setup-wifi`);

      // expect(ideMenu.submenu[idx].label).toBe('Flash device via USB')
      // expect(ideMenu.submenu[idx++].command).toBe("#{packageName()}:try-flash-usb")

      expect(ideMenu.submenu[idx++].type).toBe('separator');

      expect(ideMenu.submenu[idx].label).toBe('Compile in the cloud');
      expect(ideMenu.submenu[idx++].command).toBe(`${packageName()}:compile-cloud`);

      expect(ideMenu.submenu[idx++].type).toBe('separator');

      expect(ideMenu.submenu[idx].label).toBe('Show serial monitor');
      expect(ideMenu.submenu[idx++].command).toBe(`${packageName()}:show-serial-monitor`);

      return SettingsHelper.clearCredentials();
    });
  });

  return it('checks menu for selected device', function() {
    waitsForPromise(() => activationPromise);

    return runs(function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      atom.commands.dispatch(workspaceElement, `${packageName()}:update-menu`);

      let ideMenu = MenuManager.getMenu();

      SettingsHelper.setCurrentCore('0123456789abcdef0123456789abcdef', 'Foo');
      atom.commands.dispatch(workspaceElement, `${packageName()}:update-menu`);

      ideMenu = MenuManager.getMenu();

      expect(ideMenu.submenu.length).toBe(14);
      let idx = 3;

      expect(ideMenu.submenu[idx].label).toBe('Rename Foo...');
      expect(ideMenu.submenu[idx++].command).toBe(`${packageName()}:rename-device`);

      expect(ideMenu.submenu[idx].label).toBe('Remove Foo...');
      expect(ideMenu.submenu[idx++].command).toBe(`${packageName()}:remove-device`);

      expect(ideMenu.submenu[idx].label).toBe('Flash Foo via the cloud');
      expect(ideMenu.submenu[idx++].command).toBe(`${packageName()}:flash-cloud`);

      SettingsHelper.clearCurrentCore();
      return SettingsHelper.clearCredentials();
    });
  });
});
