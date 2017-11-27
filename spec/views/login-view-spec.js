'use babel';
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import { $ } from 'atom-space-pen-views';
import SettingsHelper from '../../lib/utils/settings-helper';
import packageName from '../../lib/utils/package-helper';
import { spark as SparkStub } from 'particle-dev-spec-stubs';
import spark from 'spark';

describe('Login View', function() {
  let activationPromise = null;
  let main = null;
  let loginView = null;
  let originalProfile = null;
  let workspaceElement = null;

  beforeEach(function() {
    workspaceElement = atom.views.getView(atom.workspace);

    activationPromise = atom.packages.activatePackage(packageName()).then(function({mainModule}) {
      main = mainModule;
      main.initView('login');
      return loginView = main.loginView;
    });

    originalProfile = SettingsHelper.getProfile();
    // For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile('test');

    return waitsForPromise(() => activationPromise);
  });

  afterEach(() => SettingsHelper.setProfile(originalProfile));

  return describe('when Login View is activated', function() {
    beforeEach(function() {
      spyOn(atom.commands, 'dispatch');
      return loginView.show();
    });

    afterEach(function() {
      loginView.hide();
      return jasmine.unspy(atom.commands, 'dispatch');
    });

    it('tests empty values', function() {
      const context = $(loginView.element);
      expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(false);
      expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(false);

      loginView.login();

      expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(true);
      expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(true);
      return expect(atom.commands.dispatch).not.toHaveBeenCalled();
    });


    it('tests invalid values', function() {
      const context = $(loginView.element);
      expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(false);
      expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(false);

      loginView.emailEditor.editor.getModel().setText('foobarbaz');
      loginView.passwordEditor.editor.getModel().setText(' ');
      loginView.login();

      expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(true);
      expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(true);
      return expect(atom.commands.dispatch).not.toHaveBeenCalled();
    });


    it('tests valid values', function() {
      SparkStub.stubSuccess(spark, 'login');

      const context = $(loginView.element);
      expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(false);
      expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(false);
      expect(loginView.spinner.hasClass('hidden')).toBe(true);

      loginView.emailEditor.editor.getModel().setText('foo@bar.baz');
      loginView.passwordEditor.editor.getModel().setText('foo');
      loginView.login();

      expect(loginView.spinner.hasClass('hidden')).toBe(false);

      waitsFor(() => !loginView.loginPromise);

      return runs(function() {
        expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(false);
        expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(false);
        expect(loginView.spinner.hasClass('hidden')).toBe(true);
        expect(atom.commands.dispatch).toHaveBeenCalled();

        expect(SettingsHelper.get('username')).toEqual('foo@bar.baz');
        expect(SettingsHelper.get('access_token')).toEqual('0123456789abcdef0123456789abcdef');

        return SettingsHelper.clearCredentials();
      });
    });


    it('tests wrong credentials', function() {
      SparkStub.stubFail(spark, 'login');

      let context = $(loginView.element);
      expect(context.find('.text-error').css('display')).toEqual('none');

      loginView.emailEditor.editor.getModel().setText('foo@bar.baz');
      loginView.passwordEditor.editor.getModel().setText('foo');
      loginView.login();

      waitsFor(() => !loginView.loginPromise);

      return runs(function() {
        context = $(loginView.element);
        expect(context.find('.text-error').css('display')).toEqual('block');
        expect(context.find('.text-error').text()).toEqual('Invalid email or password');
        return expect(loginView.spinner.hasClass('hidden')).toBe(true);
      });
    });


    return it('tests logging out', function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');

      loginView.logout();

      expect(SettingsHelper.get('username')).toEqual(null);
      return expect(SettingsHelper.get('access_token')).toEqual(null);
    });
  });
});
