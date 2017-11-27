'use babel';
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import path from 'path';
import SettingsHelper from '../../lib/utils/settings-helper';
import packageName from '../../lib/utils/package-helper';

describe('Compile Errors View', function() {
  let activationPromise = null;
  let main = null;
  let compileErrorsView = null;
  let workspaceElement = null;

  beforeEach(function() {
    workspaceElement = atom.views.getView(atom.workspace);
    activationPromise = atom.packages.activatePackage(packageName()).then(function({mainModule}) {
      main = mainModule;
      main.initView('compile-errors');
      return compileErrorsView = main.compileErrorsView;
    });

    return waitsForPromise(() => activationPromise);
  });

  return describe('', function() {
    it('tests showing without errors', function() {
      compileErrorsView.show();

      expect(compileErrorsView.find('div.loading').css('display')).toEqual('block');
      expect(compileErrorsView.find('span.loading-message').text()).toEqual('There were no compile errors');
      expect(compileErrorsView.find('ol.list-group li').length).toEqual(0);

      return compileErrorsView.hide();
    });

    return it('tests loading and selecting items', function() {
      const errors = [
        {
          text: 'Foo',
          filename: 'foo.ino',
          line: 1,
          column: 2
        },{
          text: 'Bar',
          filename: 'bar.ino',
          line: 3,
          column: 4
        }
      ];
      SettingsHelper.setLocal('compile-status', {errors});
      atom.project.setPaths([path.join(__dirname, '..', 'data', 'sampleproject')]);
      compileErrorsView.show();

      const errorElements = compileErrorsView.find('ol.list-group li');
      expect(errorElements.length).toEqual(2);

      expect(errorElements.eq(0).find('.primary-line').text()).toEqual('Foo');
      expect(errorElements.eq(1).find('.primary-line').text()).toEqual('Bar');

      expect(errorElements.eq(0).find('.secondary-line').text()).toEqual('foo.ino:1:2');
      expect(errorElements.eq(1).find('.secondary-line').text()).toEqual('bar.ino:3:4');

      // Test selecting
      const editorSpy = jasmine.createSpy('setCursorBufferPosition');
      spyOn(atom.workspace, 'open').andCallFake(() =>
        ({
          done(callback) {
            return callback({
              setCursorBufferPosition: editorSpy
            });
          }
        }));
      spyOn(compileErrorsView, 'cancel').andCallThrough();

      expect(atom.workspace.open).not.toHaveBeenCalled();

      compileErrorsView.confirmed(errors[0]);
      expect(atom.workspace.open).toHaveBeenCalled();
      expect(atom.workspace.open).toHaveBeenCalledWith(
        'foo.ino',
        {searchAllPanes: true}
      );
      expect(editorSpy).toHaveBeenCalled();
      expect(editorSpy).toHaveBeenCalledWith([0, 1]);

      jasmine.unspy(compileErrorsView, 'cancel');
      jasmine.unspy(atom.workspace, 'open');
      return SettingsHelper.setLocal('compile-status', null);
    });
  });
});
