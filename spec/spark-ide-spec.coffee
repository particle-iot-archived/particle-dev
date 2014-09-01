{WorkspaceView} = require 'atom'
SettingsHelper = require '../lib/utils/settings-helper'
SerialHelper = require '../lib/utils/serial-helper'

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
        SettingsHelper.clearCurrentCore()
        SettingsHelper.clearCredentials()
        jasmine.unspy atom, 'confirm'


  describe 'when the spark-ide:claim-core event is triggered', ->
    it 'calls claimCore() method', ->
      spyOn sparkIde, 'claimCore'
      atom.workspaceView.trigger 'spark-ide:claim-core'
      expect(sparkIde.claimCore).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'claimCore'


  describe 'when the spark-ide:identify-core event is triggered', ->
    it 'calls identifyCore() method', ->
      spyOn sparkIde, 'identifyCore'
      atom.workspaceView.trigger 'spark-ide:identify-core'
      expect(sparkIde.identifyCore).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'identifyCore'

  describe 'when identifyCore() method is called and there is only one core', ->
    it 'checks if it is identified', ->
      require 'serialport'
      require.cache[require.resolve('serialport')].exports = require './mocks/serialport-success'

      spyOn SerialHelper, 'askForCoreID'
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      atom.workspaceView.trigger 'spark-ide:identify-core'

      waitsFor ->
        !sparkIde.listPortsPromise

      runs ->
        expect(SerialHelper.askForCoreID).toHaveBeenCalled()
        expect(SerialHelper.askForCoreID).toHaveBeenCalledWith('/dev/cu.usbmodemfa1234')
        SettingsHelper.clearCredentials()
        jasmine.unspy SerialHelper, 'askForCoreID'

  describe 'when the spark-ide:compile-cloud event is triggered', ->
    it 'calls compileCloud() method', ->
      spyOn sparkIde, 'compileCloud'
      atom.workspaceView.trigger 'spark-ide:compile-cloud'
      expect(sparkIde.compileCloud).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'compileCloud'

  describe 'when the spark-ide:show-compile-errors event is triggered', ->
    it 'calls showCompileErrors() method', ->
      spyOn sparkIde, 'showCompileErrors'
      atom.workspaceView.trigger 'spark-ide:show-compile-errors'
      expect(sparkIde.showCompileErrors).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'showCompileErrors'
