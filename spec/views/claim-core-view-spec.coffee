{$} = require 'atom-space-pen-views'
SettingsHelper = require '../../lib/utils/settings-helper'
packageName = require '../../lib/utils/package-helper'
SparkStub = require('particle-dev-spec-stubs').spark
spark = require 'spark'

describe 'Claim Core View', ->
  activationPromise = null
  originalProfile = null
  main = null
  claimCoreView = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

    activationPromise = atom.packages.activatePackage(packageName()).then ({mainModule}) ->
      main = mainModule
      main.claimCoreView = null

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'test'

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
      SparkStub.stubSuccess spark, 'claimCore'
      main.claimCore()
      claimCoreView = main.claimCoreView

      editor = claimCoreView.miniEditor.editor.getModel()

      editor.setText ''
      spyOn claimCoreView, 'close'

      expect(claimCoreView.find('.editor:eq(0)').hasClass('editor-error')).toBe(false)
      atom.commands.dispatch claimCoreView.miniEditor.editor.element, 'core:confirm'
      expect(claimCoreView.find('.editor:eq(0)').hasClass('editor-error')).toBe(true)
      expect(claimCoreView.close).not.toHaveBeenCalled()

      jasmine.unspy claimCoreView, 'close'
      claimCoreView.close()


    it 'checks if proper value passes', ->
      SparkStub.stubSuccess spark, 'claimCore'
      main.claimCore()
      claimCoreView = main.claimCoreView

      editor = claimCoreView.miniEditor.editor.getModel()

      spyOn claimCoreView, 'close'
      spyOn atom.commands, 'dispatch'
      spyOn SettingsHelper, 'setCurrentCore'
      claimCoreView.onConfirm '0123456789abcdef0123456789abcdef'

      waitsFor ->
        !claimCoreView.claimPromise

      runs ->
        expect(SettingsHelper.setCurrentCore).toHaveBeenCalled()
        expect(SettingsHelper.setCurrentCore).toHaveBeenCalledWith('0123456789abcdef0123456789abcdef', null, 0)
        expect(atom.commands.dispatch).toHaveBeenCalled()
        expect(atom.commands.dispatch.calls.length).toEqual(2)
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, "#{packageName()}:update-core-status")
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, "#{packageName()}:update-menu")
        expect(claimCoreView.close).toHaveBeenCalled()

        jasmine.unspy claimCoreView, 'close'
        jasmine.unspy atom.commands, 'dispatch'
        jasmine.unspy SettingsHelper, 'setCurrentCore'
        claimCoreView.close()
