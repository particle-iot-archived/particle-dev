'use babel';
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import SettingsHelper from '../../lib/utils/settings-helper';
import packageName from '../../lib/utils/package-helper';
import { spark as SparkStub } from 'particle-dev-spec-stubs';
import spark from 'spark';

xdescribe('Status Bar Tests', function() {
  let activationPromise = null;
  let statusBarPromise = null;
  let originalProfile = null;
  let main = null;
  let statusView = null;
  let workspaceElement = null;

  beforeEach(function() {
    originalProfile = SettingsHelper.getProfile();
    // For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile('test');

    SparkStub.stubSuccess(spark, 'getAttributes');

    workspaceElement = atom.views.getView(atom.workspace);
    statusBarPromise = atom.packages.activatePackage('status-bar');

    waitsForPromise(() => statusBarPromise);

    runs(() =>
      activationPromise = atom.packages.activatePackage(packageName()).then(function({mainModule}) {
        main = mainModule;
        return statusView = main.statusView;
      })
    );

    return waitsForPromise(() => activationPromise);
  });


  afterEach(() => SettingsHelper.setProfile(originalProfile));

  describe('when the package is activated', function() {
    it('attaches custom status bar', function() {
      expect(statusView).toExist();
      expect(statusView.find('#spark-icon').is(':empty')).toBe(true);
      // User should be logged off
      expect(statusView.find('#spark-login-status a')).toExist();
      return expect(statusView.find('#spark-current-core').hasClass('hidden')).toBe(true);
    });


    it('checks if username of logged in user is shown', function() {
      // Previously logged out user
      expect(statusView.find('#spark-login-status a')).toExist();
      // Log user in
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');

      // Refresh UI
      main.statusView.updateLoginStatus();

      expect(statusView.find('#spark-login-status a')).not.toExist();
      expect(statusView.find('#spark-login-status').text()).toEqual('foo@bar.baz');

      expect(statusView.find('#spark-current-core').hasClass('hidden')).toBe(false);
      expect(statusView.find('#spark-current-core a').text()).toBe('No devices selected');

      return SettingsHelper.clearCredentials();
    });


    it('checks current core name', function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      SettingsHelper.setCurrentCore('0123456789abcdef0123456789abcdef', 'Foo');
      SparkStub.stubSuccess(spark, 'getAttributes');

      spyOn(statusView, 'getCurrentCoreStatus');
      main.statusView.updateCoreStatus();
      expect(statusView.find('#spark-current-core a').text()).toBe('Foo');
      expect(statusView.getCurrentCoreStatus).toHaveBeenCalled();

      SettingsHelper.clearCurrentCore();
      SettingsHelper.clearCredentials();
      return jasmine.unspy(statusView, 'getCurrentCoreStatus');
    });


    it('checks current core name when its null', function() {
      const statusBar = statusView.find('#spark-dev-status-bar-view');

      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      SettingsHelper.setCurrentCore('0123456789abcdef0123456789abcdef', null);
      SparkStub.stubNullName(spark, 'getAttributes');

      spyOn(statusView, 'getCurrentCoreStatus');
      main.statusView.updateCoreStatus();
      expect(statusView.find('#spark-current-core a').text()).toBe('Unnamed');
      expect(statusView.getCurrentCoreStatus).toHaveBeenCalled();

      SettingsHelper.clearCurrentCore();
      SettingsHelper.clearCredentials();
      return jasmine.unspy(statusView, 'getCurrentCoreStatus');
    });


    it('checks current core status', function() {
      // Check async core status checking
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      SettingsHelper.setCurrentCore('0123456789abcdef0123456789abcdef', 'Foo');
      SparkStub.stubSuccess(spark, 'getAttributes');

      statusView.getCurrentCoreStatus();

      waitsFor(() => !statusView.getAttributesPromise);

      runs(function() {
        expect(statusView.find('#spark-current-core').hasClass('online')).toBe(true);

        const variables = SettingsHelper.getLocal('variables');
        expect(variables).not.toBe(null);
        expect(Object.keys(variables).length).toEqual(1);
        expect(variables.foo).toEqual('int32');

        const functions = SettingsHelper.getLocal('functions');
        expect(functions).not.toBe(null);
        expect(functions.length).toEqual(1);
        expect(functions[0]).toEqual('bar');

        SparkStub.stubOffline(spark, 'getAttributes');

        return statusView.getCurrentCoreStatus();
      });

      waitsFor(() => !statusView.getAttributesPromise);

      return runs(function() {
        expect(statusView.find('#spark-current-core').hasClass('online')).toBe(false);
        clearInterval(statusView.interval);

        SettingsHelper.clearCurrentCore();
        return SettingsHelper.clearCredentials();
      });
    });

    return it('checks compile status', function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      const statusBarItem = statusView.find('#spark-compile-status');
      spyOn(SettingsHelper, 'get').andReturn(null);
      main.statusView.updateCompileStatus();
      expect(statusBarItem.hasClass('hidden')).toBe(true);
      jasmine.unspy(SettingsHelper, 'get');

      // Test compiling in progress
      SettingsHelper.setLocal('compile-status', {working:true});
      statusView.updateCompileStatus();
      expect(statusBarItem.hasClass('hidden')).toBe(false);
      expect(statusBarItem.find('#spark-compile-working').css('display')).not.toBe('none');
      expect(statusBarItem.find('#spark-compile-failed').css('display')).toBe('none');
      expect(statusBarItem.find('#spark-compile-success').css('display')).toBe('none');

      // Test errors
      SettingsHelper.setLocal('compile-status', {errors:[1]});
      statusView.updateCompileStatus();
      expect(statusBarItem.hasClass('hidden')).toBe(false);
      expect(statusBarItem.find('#spark-compile-working').css('display')).toBe('none');
      expect(statusBarItem.find('#spark-compile-failed').css('display')).not.toBe('none');
      expect(statusBarItem.find('#spark-compile-success').css('display')).toBe('none');
      expect(statusBarItem.find('#spark-compile-failed').text()).toBe('One error');

      // Test error
      SettingsHelper.setLocal('compile-status', {error:'Foo'});
      statusView.updateCompileStatus();
      expect(statusBarItem.hasClass('hidden')).toBe(false);
      expect(statusBarItem.find('#spark-compile-working').css('display')).toBe('none');
      expect(statusBarItem.find('#spark-compile-failed').css('display')).not.toBe('none');
      expect(statusBarItem.find('#spark-compile-success').css('display')).toBe('none');
      expect(statusBarItem.find('#spark-compile-failed').text()).toBe('Foo');

      // Test multiple errors
      SettingsHelper.setLocal('compile-status', {errors:[1,2]});
      statusView.updateCompileStatus();
      expect(statusBarItem.find('#spark-compile-failed').text()).toBe('2 errors');

      // Test clicking on error
      spyOn(statusView, 'showErrors');
      expect(statusView.showErrors).not.toHaveBeenCalled();
      statusBarItem.find('#spark-compile-failed').click();
      expect(statusView.showErrors).toHaveBeenCalled();
      jasmine.unspy(statusView, 'showErrors');

      // Test complete
      SettingsHelper.setLocal('compile-status', {filename:'foo.bin'});
      statusView.updateCompileStatus();
      expect(statusBarItem.hasClass('hidden')).toBe(false);
      expect(statusBarItem.find('#spark-compile-working').css('display')).toBe('none');
      expect(statusBarItem.find('#spark-compile-failed').css('display')).toBe('none');
      expect(statusBarItem.find('#spark-compile-success').css('display')).not.toBe('none');
      expect(statusBarItem.find('#spark-compile-success').text()).toBe('Success!');

      // Test clicking on filename
      spyOn(statusView, 'showFile');
      expect(statusView.showFile).not.toHaveBeenCalled();
      statusBarItem.find('#spark-compile-success').click();
      expect(statusView.showFile).toHaveBeenCalled();
      jasmine.unspy(statusView, 'showFile');

      SettingsHelper.setLocal('compile-status', null);
      return SettingsHelper.clearCredentials();
    });
  });

  return it('checks link commands', function() {
    statusView.updateLoginStatus();
    spyOn(atom.commands, 'dispatch');

    statusView.find('#spark-login-status a').click();
    expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, `${packageName()}:login`);

    SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
    atom.commands.dispatch.reset();

    statusView.find('#spark-current-core a').click();
    expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, `${packageName()}:select-device`);

    jasmine.unspy(atom.commands, 'dispatch');
    return SettingsHelper.clearCredentials();
  });
});
