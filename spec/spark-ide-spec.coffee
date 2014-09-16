{WorkspaceView} = require 'atom'
_s = require 'underscore.string'
SettingsHelper = require '../lib/utils/settings-helper'
SerialHelper = require '../lib/utils/serial-helper'
SpecHelper = require '../lib/utils/spec-helper'
SparkStub = require './stubs/spark'
spark = require 'spark'

describe 'Main Tests', ->
  activationPromise = null
  sparkIde = null
  originalProfile = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
      sparkIde = mainModule
      sparkIde.statusView = null

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-ide-test'

    waitsForPromise ->
      activationPromise

  afterEach ->
    SettingsHelper.setProfile originalProfile


  describe 'when the event is triggered, corresponging handler should be called', ->
    it 'calls login() method for spark-ide:login event', ->
      spyOn sparkIde, 'login'
      atom.workspaceView.trigger 'spark-ide:login'
      expect(sparkIde.login).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'login'

    it 'calls logout() method for spark-ide:logout event', ->
      spyOn sparkIde, 'logout'
      atom.workspaceView.trigger 'spark-ide:logout'
      expect(sparkIde.logout).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'logout'

    it 'calls selectCore() method for spark-ide:select-core event', ->
      spyOn sparkIde, 'selectCore'
      atom.workspaceView.trigger 'spark-ide:select-core'
      expect(sparkIde.selectCore).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'selectCore'

    it 'calls renameCore() method for spark-ide:rename-core event', ->
      spyOn sparkIde, 'renameCore'
      atom.workspaceView.trigger 'spark-ide:rename-core'
      expect(sparkIde.renameCore).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'renameCore'

    it 'calls removeCore() method for spark-ide:remove-core event', ->
      spyOn sparkIde, 'removeCore'
      atom.workspaceView.trigger 'spark-ide:remove-core'
      expect(sparkIde.removeCore).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'removeCore'

    it 'calls claimCore() method for spark-ide:claim-core event', ->
      spyOn sparkIde, 'claimCore'
      atom.workspaceView.trigger 'spark-ide:claim-core'
      expect(sparkIde.claimCore).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'claimCore'

    it 'calls identifyCore() method for spark-ide:identify-core event', ->
      spyOn sparkIde, 'identifyCore'
      atom.workspaceView.trigger 'spark-ide:identify-core'
      expect(sparkIde.identifyCore).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'identifyCore'

    it 'calls compileCloud() method for spark-ide:compile-cloud event', ->
      spyOn sparkIde, 'compileCloud'
      atom.workspaceView.trigger 'spark-ide:compile-cloud'
      expect(sparkIde.compileCloud).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'compileCloud'

    it 'calls showCompileErrors() method for spark-ide:show-compile-errors event', ->
      spyOn sparkIde, 'showCompileErrors'
      atom.workspaceView.trigger 'spark-ide:show-compile-errors'
      expect(sparkIde.showCompileErrors).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'showCompileErrors'

    it 'calls toggleCloudVariablesAndFunctions() method for spark-ide:toggle-cloud-variables-and-functions event', ->
      spyOn sparkIde, 'toggleCloudVariablesAndFunctions'
      atom.workspaceView.trigger 'spark-ide:toggle-cloud-variables-and-functions'
      expect(sparkIde.toggleCloudVariablesAndFunctions).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'toggleCloudVariablesAndFunctions'

    it 'calls flashCloud() method for spark-ide:flash-cloud event', ->
      spyOn sparkIde, 'flashCloud'
      atom.workspaceView.trigger 'spark-ide:flash-cloud'
      expect(sparkIde.flashCloud).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'flashCloud'


  describe 'checks logged out user', ->
    it 'checks spark-ide:remove-core', ->
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
      SparkStub.stubSuccess 'removeCore'

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
        SparkStub.stubFail 'removeCore'
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


  describe 'when identifyCore() method is called and there is only one core', ->
    it 'checks if it is identified', ->
      require 'serialport'
      require.cache[require.resolve('serialport')].exports = require './stubs/serialport-success'

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


  describe 'cloud compile tests', ->
    it 'checks if nothing is done', ->
      spyOn(atom.project, 'getPath').andReturn null

      # For logged out user
      spyOn(SettingsHelper, 'isLoggedIn').andCallThrough()
      atom.workspaceView.trigger 'spark-ide:compile-cloud'
      expect(SettingsHelper.isLoggedIn).toHaveBeenCalled()
      expect(atom.project.getPath).not.toHaveBeenCalled()

      # Not null compileCloudPromise
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      spyOn SettingsHelper, 'set'
      sparkIde.compileCloudPromise = 'foo'
      atom.workspaceView.trigger 'spark-ide:compile-cloud'
      expect(SettingsHelper.isLoggedIn.calls.length).toEqual(2)
      expect(SettingsHelper.set).not.toHaveBeenCalled()

      # Empty root directory
      sparkIde.compileCloudPromise = null
      atom.workspaceView.trigger 'spark-ide:compile-cloud'
      expect(SettingsHelper.isLoggedIn.calls.length).toEqual(3)
      expect(atom.project.getPath).toHaveBeenCalled()
      expect(SettingsHelper.set).not.toHaveBeenCalled()

      # Cleanup
      SettingsHelper.set 'compile-status', null
      jasmine.unspy SettingsHelper, 'set'
      jasmine.unspy SettingsHelper, 'isLoggedIn'
      jasmine.unspy atom.project, 'getPath'
      SettingsHelper.clearCredentials()

    it 'checks if correct files are included', ->
      oldPath = atom.project.getPath()
      atom.project.setPath __dirname + '/data/sampleproject'
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      SparkStub.stubSuccess 'compileCode'
      atom.workspaceView.trigger 'spark-ide:compile-cloud'
      # Check if local storage is set to working
      expect(SettingsHelper.get('compile-status')).toEqual({working:true})

      expect(spark.compileCode).toHaveBeenCalled()

      expectedFiles = ['foo.ino', 'lib.cpp', 'lib.h'].map (value)->
        return __dirname + '/data/sampleproject/' + value

      expect(spark.compileCode).toHaveBeenCalledWith(expectedFiles)

      SettingsHelper.set 'compile-status', null
      SettingsHelper.clearCredentials()
      atom.project.setPath oldPath

    it 'checks successful compile', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SparkStub.stubSuccess 'compileCode'
      SparkStub.stubSuccess 'downloadBinary'

      atom.workspaceView.trigger 'spark-ide:compile-cloud'
      spyOn atom.workspaceView, 'trigger'

      waitsFor ->
        !sparkIde.compileCloudPromise

      waitsFor ->
        !sparkIde.downloadBinaryPromise

      runs ->
        compileStatus = SettingsHelper.get 'compile-status'
        expect(compileStatus.filename).not.toBeUndefined()
        expect(_s.startsWith(compileStatus.filename, 'firmware')).toBe(true)
        expect(_s.endsWith(compileStatus.filename, '.bin')).toBe(true)
        expect(atom.workspaceView.trigger).toHaveBeenCalled()
        expect(atom.workspaceView.trigger.calls.length).toEqual(1)
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-ide:update-compile-status')

        SettingsHelper.set 'compile-status', null
        jasmine.unspy atom.workspaceView, 'trigger'
        SettingsHelper.clearCredentials()

    it 'checks failed compile', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SparkStub.stubFail 'compileCode'

      atom.workspaceView.trigger 'spark-ide:compile-cloud'
      spyOn atom.workspaceView, 'trigger'

      waitsFor ->
        !sparkIde.compileCloudPromise

      runs ->
        compileStatus = SettingsHelper.get 'compile-status'
        expect(compileStatus.errors).not.toBeUndefined()
        expect(compileStatus.errors.length).toEqual(1)

        expect(atom.workspaceView.trigger).toHaveBeenCalled()
        expect(atom.workspaceView.trigger.calls.length).toEqual(2)
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-ide:update-compile-status')
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-ide:show-compile-errors')

        SettingsHelper.set 'compile-status', null
        jasmine.unspy atom.workspaceView, 'trigger'
        SettingsHelper.clearCredentials()
