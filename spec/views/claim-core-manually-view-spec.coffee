{WorkspaceView} = require 'atom'
$ = require('atom').$
SettingsHelper = require '../../lib/utils/settings-helper'

describe 'Claim Core manually View', ->
  activationPromise = null
  originalProfile = null
  sparkIde = null
  claimCoreManuallyView = null

  beforeEach ->
    require '../../lib/vendor/ApiClient'
    atom.workspaceView = new WorkspaceView

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
      atom.workspaceView.trigger 'spark-ide:claim-core-manually'
      claimCoreManuallyView = sparkIde.claimCoreManuallyView

      editor = claimCoreManuallyView.miniEditor.getEditor()

      editor.setText ''
      spyOn(claimCoreManuallyView, 'close')
      expect(atom.workspaceView.find('#spark-ide-claim-core-manually-view .editor.mini:eq(0)').hasClass('editor-error')).toBe(false)
      claimCoreManuallyView.trigger 'core:confirm'
      expect(atom.workspaceView.find('#spark-ide-claim-core-manually-view .editor.mini:eq(0)').hasClass('editor-error')).toBe(true)
      expect(claimCoreManuallyView.close).not.toHaveBeenCalled()

      atom.workspaceView.trigger 'core:cancel'
      jasmine.unspy claimCoreManuallyView, 'close'


    it 'claims the core', ->
      require.cache[require.resolve('../../lib/vendor/ApiClient')].exports = require '../mocks/ApiClient-success'
      atom.workspaceView.trigger 'spark-ide:claim-core-manually'
      claimCoreManuallyView = sparkIde.claimCoreManuallyView

      editor = claimCoreManuallyView.miniEditor.getEditor()

      editor.setText '0123456789abcdef0123456789abcdef'
      spyOn(claimCoreManuallyView, 'close')
      spyOn(atom.workspaceView, 'trigger')
      claimCoreManuallyView.trigger 'core:confirm'

      waitsFor ->
        !claimCoreManuallyView.claimPromise

      runs ->
        expect(SettingsHelper.get('current_core')).toBe('0123456789abcdef0123456789abcdef')
        expect(SettingsHelper.get('current_core_name')).toBe('0123456789abcdef0123456789abcdef')
        expect(atom.workspaceView.trigger).toHaveBeenCalled()
        expect(atom.workspaceView.trigger.calls.length).toEqual(2)
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-ide:update-core-status')
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-ide:update-menu')
        expect(claimCoreManuallyView.close).toHaveBeenCalled()

        jasmine.unspy claimCoreManuallyView, 'close'
        jasmine.unspy atom.workspaceView, 'trigger'
        claimCoreManuallyView.close()
