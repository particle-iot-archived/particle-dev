SettingsHelper = require '../../lib/utils/settings-helper'
RenameCoreView = require '../../lib/views/rename-core-view'
SparkStub = require('particle-dev-spec-stubs').spark
spark = require 'spark'

describe 'Rename Core View', ->
  activationPromise = null
  originalProfile = null
  sparkIde = null
  renameCoreView = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('spark-dev').then ({mainModule}) ->
      sparkIde = mainModule
      sparkIde.initView 'rename-core'
      renameCoreView = new RenameCoreView()

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-dev-test'

    waitsForPromise ->
      activationPromise

  afterEach ->
    SettingsHelper.setProfile originalProfile

  describe '', ->
    beforeEach ->
      spyOn atom.commands, 'dispatch'
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'

    afterEach ->
      SettingsHelper.clearCurrentCore()
      SettingsHelper.clearCredentials()
      jasmine.unspy atom.commands, 'dispatch'

    it 'checks if empty name would cause an error', ->
      renameCoreView = new RenameCoreView('Foo')
      renameCoreView.show()

      editor = renameCoreView.miniEditor.editor.getModel()
      expect(editor.getText()).toBe('Foo')

      spyOn renameCoreView, 'close'
      expect(renameCoreView.find('.editor:eq(0)').hasClass('editor-error')).toBe(false)
      renameCoreView.onConfirm ''
      expect(renameCoreView.find('.editor:eq(0)').hasClass('editor-error')).toBe(true)
      expect(renameCoreView.close).not.toHaveBeenCalled()

      jasmine.unspy renameCoreView, 'close'
      renameCoreView.close()

    it 'renames the core', ->
      SparkStub.stubSuccess spark, 'renameCore'
      renameCoreView = new RenameCoreView('Foo')
      renameCoreView.show()

      editor = renameCoreView.miniEditor.editor.getModel()

      spyOn renameCoreView, 'close'
      renameCoreView.onConfirm 'Bar'

      waitsFor ->
        !renameCoreView.renamePromise

      runs ->
        expect(SettingsHelper.getLocal('current_core_name')).toBe('Bar')
        expect(atom.commands.dispatch).toHaveBeenCalled()
        expect(atom.commands.dispatch.calls.length).toEqual(2)
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, 'spark-dev:update-core-status')
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, 'spark-dev:update-menu')
        expect(renameCoreView.close).toHaveBeenCalled()

        jasmine.unspy renameCoreView, 'close'
        renameCoreView.close()

    it 'checks null core name', ->
      SparkStub.stubSuccess spark, 'renameCore'

      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', null
      sparkIde.renameCore()
