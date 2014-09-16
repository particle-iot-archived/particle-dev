{WorkspaceView} = require 'atom'
$ = require('atom').$
SettingsHelper = require '../../lib/utils/settings-helper'
SparkStub = require '../stubs/spark'

describe 'Rename Core View', ->
  activationPromise = null
  originalProfile = null
  sparkIde = null
  renameCoreView = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView

    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
      sparkIde = mainModule
      sparkIde.renameCoreView = null

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-ide-test'

    waitsForPromise ->
      activationPromise

  afterEach ->
    SettingsHelper.setProfile originalProfile

  describe '', ->
    beforeEach ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'

    afterEach ->
      SettingsHelper.clearCurrentCore()
      SettingsHelper.clearCredentials()

    it 'checks if empty name would cause an error', ->
      atom.workspaceView.trigger 'spark-ide:rename-core'
      renameCoreView = sparkIde.renameCoreView

      editor = renameCoreView.miniEditor.getEditor()
      expect(editor.getText()).toBe('Foo')

      editor.setText ''
      spyOn renameCoreView, 'close'
      expect(atom.workspaceView.find('#spark-ide-rename-core-view .editor:eq(0)').hasClass('editor-error')).toBe(false)
      renameCoreView.trigger 'core:confirm'
      expect(atom.workspaceView.find('#spark-ide-rename-core-view .editor:eq(0)').hasClass('editor-error')).toBe(true)
      expect(renameCoreView.close).not.toHaveBeenCalled()

      atom.workspaceView.trigger 'core:cancel'
      jasmine.unspy renameCoreView, 'close'

    it 'renames the core', ->
      SparkStub.stubSuccess 'renameCore'
      atom.workspaceView.trigger 'spark-ide:rename-core'
      renameCoreView = sparkIde.renameCoreView

      editor = renameCoreView.miniEditor.getEditor()

      editor.setText 'Bar'
      spyOn renameCoreView, 'close'
      spyOn atom.workspaceView, 'trigger'
      renameCoreView.trigger 'core:confirm'

      waitsFor ->
        !renameCoreView.renamePromise

      runs ->
        expect(SettingsHelper.get('current_core_name')).toBe('Bar')
        expect(atom.workspaceView.trigger).toHaveBeenCalled()
        expect(atom.workspaceView.trigger.calls.length).toEqual(2)
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-ide:update-core-status')
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-ide:update-menu')
        expect(renameCoreView.close).toHaveBeenCalled()

        jasmine.unspy renameCoreView, 'close'
        jasmine.unspy atom.workspaceView, 'trigger'
        renameCoreView.close()
