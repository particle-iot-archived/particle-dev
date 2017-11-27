'use babel';
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import SettingsHelper from '../../lib/utils/settings-helper';
import RenameCoreView from '../../lib/views/rename-core-view';
import packageName from '../../lib/utils/package-helper';
import { spark as SparkStub } from 'particle-dev-spec-stubs';
import spark from 'spark';

describe('Rename Core View', function() {
  let activationPromise = null;
  let originalProfile = null;
  let main = null;
  let renameCoreView = null;
  let workspaceElement = null;

  beforeEach(function() {
    workspaceElement = atom.views.getView(atom.workspace);
    activationPromise = atom.packages.activatePackage(packageName()).then(function({mainModule}) {
      main = mainModule;
      main.initView('rename-core');
      return renameCoreView = new RenameCoreView();
    });

    originalProfile = SettingsHelper.getProfile();
    // For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile('test');

    return waitsForPromise(() => activationPromise);
  });

  afterEach(() => SettingsHelper.setProfile(originalProfile));

  return describe('', function() {
    beforeEach(function() {
      spyOn(atom.commands, 'dispatch');
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      return SettingsHelper.setCurrentCore('0123456789abcdef0123456789abcdef', 'Foo');
    });

    afterEach(function() {
      SettingsHelper.clearCurrentCore();
      SettingsHelper.clearCredentials();
      return jasmine.unspy(atom.commands, 'dispatch');
    });

    it('checks if empty name would cause an error', function() {
      renameCoreView = new RenameCoreView('Foo');
      renameCoreView.show();

      const editor = renameCoreView.miniEditor.editor.getModel();
      expect(editor.getText()).toBe('Foo');

      spyOn(renameCoreView, 'close');
      expect(renameCoreView.find('.editor:eq(0)').hasClass('editor-error')).toBe(false);
      renameCoreView.onConfirm('');
      expect(renameCoreView.find('.editor:eq(0)').hasClass('editor-error')).toBe(true);
      expect(renameCoreView.close).not.toHaveBeenCalled();

      jasmine.unspy(renameCoreView, 'close');
      return renameCoreView.close();
    });

    it('renames the core', function() {
      SparkStub.stubSuccess(spark, 'renameCore');
      renameCoreView = new RenameCoreView('Foo');
      renameCoreView.show();

      const editor = renameCoreView.miniEditor.editor.getModel();

      spyOn(renameCoreView, 'close');
      renameCoreView.onConfirm('Bar');

      waitsFor(() => !renameCoreView.renamePromise);

      return runs(function() {
        expect(SettingsHelper.getLocal('current_core_name')).toBe('Bar');
        expect(atom.commands.dispatch).toHaveBeenCalled();
        expect(atom.commands.dispatch.calls.length).toEqual(2);
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, `${packageName()}:update-core-status`);
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, `${packageName()}:update-menu`);
        expect(renameCoreView.close).toHaveBeenCalled();

        jasmine.unspy(renameCoreView, 'close');
        return renameCoreView.close();
      });
    });

    return it('checks null core name', function() {
      SparkStub.stubSuccess(spark, 'renameCore');

      SettingsHelper.setCurrentCore('0123456789abcdef0123456789abcdef', null);
      return main.renameCore();
    });
  });
});
