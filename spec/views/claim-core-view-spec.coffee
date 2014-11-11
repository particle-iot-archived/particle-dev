{WorkspaceView} = require 'atom'
$ = require('atom').$
SettingsHelper = require '../../lib/utils/settings-helper'
SparkStub = require '../stubs/spark'

describe 'Claim Core View', ->
  activationPromise = null
  originalProfile = null
  sparkIde = null
  claimCoreView = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView

    activationPromise = atom.packages.activatePackage('spark-dev').then ({mainModule}) ->
      sparkIde = mainModule
      sparkIde.claimCoreView = null

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-dev-test'

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
      sparkIde.claimCore()
      claimCoreView = sparkIde.claimCoreView

      editor = claimCoreView.miniEditor.getEditor()

      editor.setText ''
      spyOn claimCoreView, 'close'

      expect(atom.workspaceView.find('#spark-dev-claim-core-view .editor:eq(0)').hasClass('editor-error')).toBe(false)
      claimCoreView.trigger 'core:confirm'
      expect(atom.workspaceView.find('#spark-dev-claim-core-view .editor:eq(0)').hasClass('editor-error')).toBe(true)
      expect(claimCoreView.close).not.toHaveBeenCalled()

      atom.workspaceView.trigger 'core:cancel'
      jasmine.unspy claimCoreView, 'close'


    it 'claims the core', ->
      SparkStub.stubSuccess 'claimCore'
      sparkIde.claimCore()
      claimCoreView = sparkIde.claimCoreView

      editor = claimCoreView.miniEditor.getEditor()

      editor.setText '0123456789abcdef0123456789abcdef'
      spyOn claimCoreView, 'close'
      spyOn atom.workspaceView, 'trigger'
      claimCoreView.trigger 'core:confirm'

      waitsFor ->
        !claimCoreView.claimPromise

      runs ->
        expect(SettingsHelper.get('current_core')).toBe('0123456789abcdef0123456789abcdef')
        expect(SettingsHelper.get('current_core_name')).toBe('0123456789abcdef0123456789abcdef')
        expect(atom.workspaceView.trigger).toHaveBeenCalled()
        expect(atom.workspaceView.trigger.calls.length).toEqual(2)
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-dev:update-core-status')
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-dev:update-menu')
        expect(claimCoreView.close).toHaveBeenCalled()

        jasmine.unspy claimCoreView, 'close'
        jasmine.unspy atom.workspaceView, 'trigger'
        claimCoreView.close()
