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

describe('Claim Core View', function() {
  let activationPromise = null;
  let originalProfile = null;
  let main = null;
  let claimCoreView = null;
  let workspaceElement = null;

  beforeEach(function() {
    workspaceElement = atom.views.getView(atom.workspace);

    activationPromise = atom.packages.activatePackage(packageName()).then(function({mainModule}) {
      main = mainModule;
      return main.claimCoreView = null;
    });

    originalProfile = SettingsHelper.getProfile();
    // For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile('test');

    return waitsForPromise(() => activationPromise);
  });

  afterEach(() => SettingsHelper.setProfile(originalProfile));

  return describe('', function() {
    beforeEach(function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      return SettingsHelper.setCurrentCore('0123456789abcdef0123456789abcdef', 'Foo');
    });

    afterEach(function() {
      SettingsHelper.clearCurrentCore();
      return SettingsHelper.clearCredentials();
    });

    it('checks if empty name would cause an error', function() {
      SparkStub.stubSuccess(spark, 'claimCore');
      main.claimCore();
      ({ claimCoreView } = main);

      const editor = claimCoreView.miniEditor.editor.getModel();

      editor.setText('');
      spyOn(claimCoreView, 'close');

      expect(claimCoreView.find('.editor:eq(0)').hasClass('editor-error')).toBe(false);
      atom.commands.dispatch(claimCoreView.miniEditor.editor.element, 'core:confirm');
      expect(claimCoreView.find('.editor:eq(0)').hasClass('editor-error')).toBe(true);
      expect(claimCoreView.close).not.toHaveBeenCalled();

      jasmine.unspy(claimCoreView, 'close');
      return claimCoreView.close();
    });


    return it('checks if proper value passes', function() {
      SparkStub.stubSuccess(spark, 'claimCore');
      main.claimCore();
      ({ claimCoreView } = main);

      const editor = claimCoreView.miniEditor.editor.getModel();

      spyOn(claimCoreView, 'close');
      spyOn(atom.commands, 'dispatch');
      spyOn(SettingsHelper, 'setCurrentCore');
      claimCoreView.onConfirm('0123456789abcdef0123456789abcdef');

      waitsFor(() => !claimCoreView.claimPromise);

      return runs(function() {
        expect(SettingsHelper.setCurrentCore).toHaveBeenCalled();
        expect(SettingsHelper.setCurrentCore).toHaveBeenCalledWith('0123456789abcdef0123456789abcdef', null, 0);
        expect(atom.commands.dispatch).toHaveBeenCalled();
        expect(atom.commands.dispatch.calls.length).toEqual(2);
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, `${packageName()}:update-core-status`);
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, `${packageName()}:update-menu`);
        expect(claimCoreView.close).toHaveBeenCalled();

        jasmine.unspy(claimCoreView, 'close');
        jasmine.unspy(atom.commands, 'dispatch');
        jasmine.unspy(SettingsHelper, 'setCurrentCore');
        return claimCoreView.close();
      });
    });
  });
});
