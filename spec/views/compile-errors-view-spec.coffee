path = require 'path'
SettingsHelper = require '../../lib/utils/settings-helper'

describe 'Compile Errors View', ->
  activationPromise = null
  sparkIde = null
  compileErrorsView = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('spark-dev').then ({mainModule}) ->
      sparkIde = mainModule
      sparkIde.initView 'compile-errors'
      compileErrorsView = sparkIde.compileErrorsView

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
      SettingsHelper.setLocal 'compile-status', {errors: [
        {
          message: 'Foo',
          file: 'foo.ino',
          row: 1,
          col: 2
        },{
          message: 'Bar',
          file: 'bar.ino',
          row: 3,
          col: 4
        }
      ]}
      atom.project.setPaths [path.join(__dirname, '..', 'data', 'sampleproject')]
      compileErrorsView.show()

      errors = compileErrorsView.find('ol.list-group li')
      expect(errors.length).toEqual(2)

      expect(errors.eq(0).find('.primary-line').text()).toEqual('Foo')
      expect(errors.eq(1).find('.primary-line').text()).toEqual('Bar')

      expect(errors.eq(0).find('.secondary-line').text()).toEqual('foo.ino:1:2')
      expect(errors.eq(1).find('.secondary-line').text()).toEqual('bar.ino:3:4')

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
      errors.eq(0).addClass 'selected'
      atom.commands.dispatch compileErrorsView.element, 'core:confirm'
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
