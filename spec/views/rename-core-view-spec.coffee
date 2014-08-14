{WorkspaceView} = require 'atom'
$ = require('atom').$
SettingsHelper = require '../../lib/utils/settings-helper'

describe 'Rename Core View', ->
  activationPromise = null
  treeViewPromise = null
  originalProfile = null
  sparkIde = null
  renameCoreView = null

  beforeEach ->
    require '../../lib/vendor/ApiClient'
    atom.workspaceView = new WorkspaceView

    treeViewPromise = atom.packages.activatePackage('tree-view')

    waitsForPromise ->
      treeViewPromise

    runs ->
      activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
        sparkIde = mainModule

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
      SettingsHelper.clearCredentials()
      SettingsHelper.clearCurrentCore()

    it 'checks if empty name would cause an error', ->
      atom.workspaceView.trigger 'spark-ide:rename-core'
      renameCoreView = sparkIde.renameCoreView

      editor = renameCoreView.miniEditor.getEditor()
      expect(editor.getText()).toBe('Foo')

      editor.setText ''
      spyOn(renameCoreView, 'close')
      expect(atom.workspaceView.find('#spark-ide-rename-core-view .editor.mini:eq(0)').hasClass('editor-error')).toBe(false)
      renameCoreView.trigger 'core:confirm'
      expect(atom.workspaceView.find('#spark-ide-rename-core-view .editor.mini:eq(0)').hasClass('editor-error')).toBe(true)
      expect(renameCoreView.close).not.toHaveBeenCalled()

      atom.workspaceView.trigger 'core:cancel'

    it 'removes the core', ->
      require.cache[require.resolve('../../lib/vendor/ApiClient')].exports = require '../mocks/ApiClient-success'
      atom.workspaceView.trigger 'spark-ide:rename-core'
      renameCoreView = sparkIde.renameCoreView

      editor = renameCoreView.miniEditor.getEditor()
      expect(editor.getText()).toBe('Foo')

      editor.setText 'Bar'
      spyOn(renameCoreView, 'close')
      spyOn(atom.workspaceView, 'trigger')
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

        jasmine.unspy(renameCoreView, 'close')
        jasmine.unspy(atom.workspaceView, 'trigger')
        renameCoreView.close()
