path = require 'path'
SettingsHelper = require '../../lib/utils/settings-helper'
packageName = require '../../lib/utils/package-helper'

describe 'Compile Errors View', ->
  activationPromise = null
  main = null
  compileErrorsView = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage(packageName()).then ({mainModule}) ->
      main = mainModule
      main.initView 'compile-errors'
      compileErrorsView = main.compileErrorsView

    waitsForPromise ->
      activationPromise

  describe '', ->
    it 'tests showing without errors', ->
      compileErrorsView.show()

      expect(compileErrorsView.find('div.loading').css('display')).toEqual('block')
      expect(compileErrorsView.find('span.loading-message').text()).toEqual('There were no compile errors')
      expect(compileErrorsView.find('ol.list-group li').length).toEqual(0)

      compileErrorsView.hide()

    it 'tests loading and selecting items', ->
      errors = [
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
      ]
      SettingsHelper.setLocal 'compile-status', {errors: errors}
      atom.project.setPaths [path.join(__dirname, '..', 'data', 'sampleproject')]
      compileErrorsView.show()

      errorElements = compileErrorsView.find('ol.list-group li')
      expect(errorElements.length).toEqual(2)

      expect(errorElements.eq(0).find('.primary-line').text()).toEqual('Foo')
      expect(errorElements.eq(1).find('.primary-line').text()).toEqual('Bar')

      expect(errorElements.eq(0).find('.secondary-line').text()).toEqual('foo.ino:1:2')
      expect(errorElements.eq(1).find('.secondary-line').text()).toEqual('bar.ino:3:4')

      # Test selecting
      editorSpy = jasmine.createSpy 'setCursorBufferPosition'
      spyOn(atom.workspace, 'open').andCallFake ->
        return {
          done: (callback) ->
            callback {
              setCursorBufferPosition: editorSpy
            }
        }
      spyOn(compileErrorsView, 'cancel').andCallThrough()

      expect(atom.workspace.open).not.toHaveBeenCalled()

      compileErrorsView.confirmed(errors[0])
      expect(atom.workspace.open).toHaveBeenCalled()
      expect(atom.workspace.open).toHaveBeenCalledWith(
        'foo.ino',
        {searchAllPanes: true}
      )
      expect(editorSpy).toHaveBeenCalled()
      expect(editorSpy).toHaveBeenCalledWith([0, 1])

      jasmine.unspy compileErrorsView, 'cancel'
      jasmine.unspy atom.workspace, 'open'
      SettingsHelper.setLocal 'compile-status', null
