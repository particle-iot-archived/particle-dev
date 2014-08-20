{WorkspaceView} = require 'atom'
SettingsHelper = require '../lib/utils/settings-helper'

describe 'Main Tests', ->
  activationPromise = null
  loginView = null
  sparkIde = null
  originalProfile = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
      sparkIde = mainModule
      loginView = mainModule.loginView

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-ide-test'

    waitsForPromise ->
      activationPromise

  afterEach ->
    SettingsHelper.setProfile originalProfile


  describe 'when the spark-ide:login event is triggered', ->
    it 'calls login() method', ->
      spyOn sparkIde, 'login'
      atom.workspaceView.trigger 'spark-ide:login'
      expect(sparkIde.login).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'login'


  describe 'when the spark-ide:logout event is triggered', ->
    it 'calls logout() method', ->
      spyOn sparkIde, 'logout'
      atom.workspaceView.trigger 'spark-ide:logout'
      expect(sparkIde.logout).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'logout'


  describe 'when the spark-ide:select-core event is triggered', ->
    it 'calls selectCore() method', ->
      spyOn sparkIde, 'selectCore'
      atom.workspaceView.trigger 'spark-ide:select-core'
      expect(sparkIde.selectCore).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'selectCore'


  describe 'when the spark-ide:rename-core event is triggered', ->
    it 'calls renameCore() method', ->
      spyOn sparkIde, 'renameCore'
      atom.workspaceView.trigger 'spark-ide:rename-core'
      expect(sparkIde.renameCore).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'renameCore'


  describe 'when the spark-ide:remove-core event is triggered', ->
    it 'calls removeCore() method', ->
      spyOn sparkIde, 'removeCore'
      atom.workspaceView.trigger 'spark-ide:remove-core'

      expect(sparkIde.removeCore).toHaveBeenCalled()

      jasmine.unspy sparkIde, 'removeCore'

    it 'does nothing for logged out user', ->
      spyOn atom, 'confirm'
      atom.workspaceView.trigger 'spark-ide:remove-core'

      expect(atom.confirm).not.toHaveBeenCalled()

      jasmine.unspy atom, 'confirm'

    it 'does nothing for logged in user without selected core', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      spyOn atom, 'confirm'
      atom.workspaceView.trigger 'spark-ide:remove-core'

      expect(atom.confirm).not.toHaveBeenCalled()

      SettingsHelper.clearCredentials()
      jasmine.unspy atom, 'confirm'

    it 'asks for confirmation for logged in user with selected core', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      spyOn atom, 'confirm'
      atom.workspaceView.trigger 'spark-ide:remove-core'

      expect(atom.confirm).toHaveBeenCalled()
      expect(atom.confirm.calls.length).toEqual(1)
      expect(atom.confirm.calls[0].args.length).toEqual(1)
      args = atom.confirm.calls[0].args[0]

      expect(args.message).toEqual('Removal confirmation')
      expect(args.detailedMessage).toEqual('Do you really want to remove Foo?')
      expect('Cancel' of args.buttons).toEqual(true)
      expect('Remove Foo' of args.buttons).toEqual(true)

      # Test remove callback
      require.cache[require.resolve('../lib/vendor/ApiClient')].exports = require './mocks/ApiClient-success'
      spyOn SettingsHelper, 'clearCurrentCore'
      spyOn atom.workspaceView, 'trigger'
      args.buttons['Remove Foo']()

      waitsFor ->
        !sparkIde.removePromise

      runs ->
        expect(SettingsHelper.clearCurrentCore).toHaveBeenCalled()
        expect(atom.workspaceView.trigger).toHaveBeenCalled()
        expect(atom.workspaceView.trigger.calls.length).toEqual(2)
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-ide:update-core-status')
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-ide:update-menu')

        # Test fail
        require.cache[require.resolve('../lib/vendor/ApiClient')].exports = require './mocks/ApiClient-fail'
        args.buttons['Remove Foo']()

      waitsFor ->
        !sparkIde.removePromise

      runs ->
        expect(atom.confirm.calls.length).toEqual(2)
        expect(atom.confirm.calls[1].args.length).toEqual(1)
        alertArgs = atom.confirm.calls[1].args[0]
        expect(alertArgs.message).toEqual('Permission Denied')
        expect(alertArgs.detailedMessage).toEqual('I didn\'t recognize that core name or ID')

        jasmine.unspy SettingsHelper, 'clearCurrentCore'
        jasmine.unspy(atom.workspaceView, 'trigger')
        SettingsHelper.clearCredentials()
        SettingsHelper.clearCurrentCore()
        jasmine.unspy atom, 'confirm'


  describe 'when the spark-ide:claim-core-manually event is triggered', ->
    it 'calls claimCoreManually() method', ->
      spyOn sparkIde, 'claimCoreManually'
      atom.workspaceView.trigger 'spark-ide:claim-core-manually'
      expect(sparkIde.claimCoreManually).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'claimCoreManually'


  describe 'when the spark-ide:claim-core-usb event is triggered', ->
    it 'calls claimCoreUsb() method', ->
      spyOn sparkIde, 'claimCoreUsb'
      atom.workspaceView.trigger 'spark-ide:claim-core-usb'
      expect(sparkIde.claimCoreUsb).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'claimCoreUsb'
