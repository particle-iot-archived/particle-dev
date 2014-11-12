{WorkspaceView} = require 'atom'
_s = require 'underscore.string'
spark = require 'spark'
fs = require 'fs-plus'
SettingsHelper = require '../lib/utils/settings-helper'
SerialHelper = require '../lib/utils/serial-helper'
utilities = require '../lib/vendor/utilities'
SparkStub = require './stubs/spark'

describe 'Main Tests', ->
  activationPromise = null
  sparkIde = null
  originalProfile = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-dev').then ({mainModule}) ->
      sparkIde = mainModule
      # sparkIde.statusView = null

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-dev-test'

    waitsForPromise ->
      activationPromise

  afterEach ->
    SettingsHelper.setProfile originalProfile


  describe 'when the event is triggered, corresponging handler should be called', ->
    it 'calls login() method for spark-dev:login event', ->
      spyOn sparkIde, 'login'
      atom.workspaceView.trigger 'spark-dev:login'
      expect(sparkIde.login).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'login'

    it 'calls logout() method for spark-dev:logout event', ->
      spyOn sparkIde, 'logout'
      atom.workspaceView.trigger 'spark-dev:logout'
      expect(sparkIde.logout).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'logout'

    it 'calls selectCore() method for spark-dev:select-device event', ->
      spyOn sparkIde, 'selectCore'
      atom.workspaceView.trigger 'spark-dev:select-device'
      expect(sparkIde.selectCore).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'selectCore'

    it 'calls renameCore() method for spark-dev:rename-device event', ->
      spyOn sparkIde, 'renameCore'
      atom.workspaceView.trigger 'spark-dev:rename-device'
      expect(sparkIde.renameCore).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'renameCore'

    it 'calls removeCore() method for spark-dev:remove-device event', ->
      spyOn sparkIde, 'removeCore'
      atom.workspaceView.trigger 'spark-dev:remove-device'
      expect(sparkIde.removeCore).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'removeCore'

    it 'calls claimCore() method for spark-dev:claim-device event', ->
      spyOn sparkIde, 'claimCore'
      atom.workspaceView.trigger 'spark-dev:claim-device'
      expect(sparkIde.claimCore).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'claimCore'

    it 'calls identifyCore() method for spark-dev:identify-device event', ->
      spyOn sparkIde, 'identifyCore'
      atom.workspaceView.trigger 'spark-dev:identify-device'
      expect(sparkIde.identifyCore).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'identifyCore'

    it 'calls compileCloud() method for spark-dev:compile-cloud event', ->
      spyOn sparkIde, 'compileCloud'
      atom.workspaceView.trigger 'spark-dev:compile-cloud'
      expect(sparkIde.compileCloud).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'compileCloud'

    it 'calls showCompileErrors() method for spark-dev:show-compile-errors event', ->
      spyOn sparkIde, 'showCompileErrors'
      atom.workspaceView.trigger 'spark-dev:show-compile-errors'
      expect(sparkIde.showCompileErrors).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'showCompileErrors'

    it 'calls showCloudVariablesAndFunctions() method for spark-dev:show-cloud-variables-and-functions event', ->
      spyOn sparkIde, 'showCloudVariablesAndFunctions'
      atom.workspaceView.trigger 'spark-dev:show-cloud-variables-and-functions'
      expect(sparkIde.showCloudVariablesAndFunctions).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'showCloudVariablesAndFunctions'

    it 'calls flashCloud() method for spark-dev:flash-cloud event', ->
      spyOn sparkIde, 'flashCloud'
      atom.workspaceView.trigger 'spark-dev:flash-cloud'
      expect(sparkIde.flashCloud).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'flashCloud'

    it 'calls flashCloud() method for spark-dev:flash-cloud event', ->
      spyOn sparkIde, 'flashCloud'
      atom.workspaceView.trigger 'spark-dev:flash-cloud'
      expect(sparkIde.flashCloud).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'flashCloud'

    it 'calls showSerialMonitor() method for spark-dev:show-serial-monitor event', ->
      spyOn sparkIde, 'showSerialMonitor'
      atom.workspaceView.trigger 'spark-dev:show-serial-monitor'
      expect(sparkIde.showSerialMonitor).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'showSerialMonitor'

    it 'calls setupWifi() method for spark-dev:setup-wifi event', ->
      spyOn sparkIde, 'setupWifi'
      atom.workspaceView.trigger 'spark-dev:setup-wifi'
      expect(sparkIde.setupWifi).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'setupWifi'


  describe 'checks logged out user', ->
    it 'checks spark-dev:remove-device', ->
      spyOn atom, 'confirm'
      sparkIde.removeCore()
      expect(atom.confirm).not.toHaveBeenCalled()
      jasmine.unspy atom, 'confirm'

    it 'does nothing for logged in user without selected core', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      spyOn atom, 'confirm'
      sparkIde.removeCore()

      expect(atom.confirm).not.toHaveBeenCalled()

      SettingsHelper.clearCredentials()
      jasmine.unspy atom, 'confirm'

    it 'asks for confirmation for logged in user with selected core', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      spyOn atom, 'confirm'
      sparkIde.removeCore()

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
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-dev:update-core-status')
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-dev:update-menu')

        # Test fail
        SparkStub.stubFail 'removeCore'
        args.buttons['Remove Foo']()

      waitsFor ->
        !sparkIde.removePromise

      runs ->
        expect(atom.confirm.calls.length).toEqual(2)
        expect(atom.confirm.calls[1].args.length).toEqual(1)
        alertArgs = atom.confirm.calls[1].args[0]
        expect(alertArgs.message).toEqual('Error')
        expect(alertArgs.detailedMessage).toEqual('I didn\'t recognize that device name or ID')

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

      sparkIde.identifyCore()

      waitsFor ->
        !sparkIde.listPortsPromise

      runs ->
        expect(SerialHelper.askForCoreID).toHaveBeenCalled()
        expect(SerialHelper.askForCoreID).toHaveBeenCalledWith('/dev/cu.usbmodemfa1234')
        SettingsHelper.clearCredentials()
        jasmine.unspy SerialHelper, 'askForCoreID'


  describe 'cloud compile tests', ->
    it 'checks if nothing is done', ->
      spyOn(atom.project, 'getPaths').andReturn []

      # For logged out user
      spyOn(SettingsHelper, 'isLoggedIn').andCallThrough()
      sparkIde.compileCloud()
      expect(SettingsHelper.isLoggedIn).toHaveBeenCalled()
      expect(atom.project.getPaths).not.toHaveBeenCalled()

      # Not null compileCloudPromise
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      spyOn SettingsHelper, 'set'
      sparkIde.compileCloudPromise = 'foo'
      sparkIde.compileCloud()
      expect(SettingsHelper.isLoggedIn.calls.length).toEqual(2)
      expect(SettingsHelper.set).not.toHaveBeenCalled()

      # Empty root directory
      sparkIde.compileCloudPromise = null
      sparkIde.compileCloud()
      expect(SettingsHelper.isLoggedIn.calls.length).toEqual(3)
      expect(atom.project.getPaths).toHaveBeenCalled()
      expect(SettingsHelper.set).not.toHaveBeenCalled()

      # Cleanup
      SettingsHelper.set 'compile-status', null
      jasmine.unspy SettingsHelper, 'set'
      jasmine.unspy SettingsHelper, 'isLoggedIn'
      jasmine.unspy atom.project, 'getPaths'
      SettingsHelper.clearCredentials()

    it 'checks if correct files are included', ->
      oldPaths = atom.project.getPaths()
      atom.project.setPaths [__dirname + '/data/sampleproject']
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      SparkStub.stubSuccess 'compileCode'
      sparkIde.compileCloud()
      # Check if local storage is set to working
      expect(SettingsHelper.get('compile-status')).toEqual({working:true})

      expect(spark.compileCode).toHaveBeenCalled()

      expectedFiles = ['foo.ino', 'inner/bar.cpp', 'lib.cpp', 'lib.h']

      expect(spark.compileCode).toHaveBeenCalledWith(expectedFiles)

      waitsFor ->
        !sparkIde.compileCloudPromise

      runs ->
        SettingsHelper.set 'compile-status', null
        SettingsHelper.clearCredentials()
        atom.project.setPaths oldPaths

        # Remove firmware files
        for file in fs.listSync(__dirname + '/data/sampleproject')
          if utilities.getFilenameExt(file).toLowerCase() == '.bin'
            fs.unlinkSync file

    it 'checks successful compile', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SparkStub.stubSuccess 'compileCode'
      SparkStub.stubSuccess 'downloadBinary'

      spyOn atom.workspaceView, 'trigger'
      sparkIde.compileCloud()

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
        expect(atom.workspaceView.trigger.calls.length).toEqual(2)
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-dev:update-compile-status')
        expect(atom.workspaceView.trigger).not.toHaveBeenCalledWith('spark-dev:flash-cloud')

        SettingsHelper.set 'compile-status', null
        jasmine.unspy atom.workspaceView, 'trigger'
        SettingsHelper.clearCredentials()

    it 'checks failed compile', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SparkStub.stubFail 'compileCode'

      spyOn atom.workspaceView, 'trigger'
      sparkIde.compileCloud()

      waitsFor ->
        !sparkIde.compileCloudPromise

      runs ->
        compileStatus = SettingsHelper.get 'compile-status'
        expect(compileStatus.errors).not.toBeUndefined()
        expect(compileStatus.errors.length).toEqual(1)

        expect(atom.workspaceView.trigger).toHaveBeenCalled()
        expect(atom.workspaceView.trigger.calls.length).toEqual(3)
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-dev:update-compile-status')
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-dev:show-compile-errors')

        SettingsHelper.set 'compile-status', null
        jasmine.unspy atom.workspaceView, 'trigger'
        SettingsHelper.clearCredentials()

    it 'checks flashing after compiling', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SparkStub.stubSuccess 'compileCode'
      SparkStub.stubSuccess 'downloadBinary'

      spyOn atom.workspaceView, 'trigger'
      sparkIde.compileCloud true

      waitsFor ->
        !sparkIde.compileCloudPromise

      waitsFor ->
        !sparkIde.downloadBinaryPromise

      runs ->
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-dev:flash-cloud')

        SettingsHelper.set 'compile-status', null
        jasmine.unspy atom.workspaceView, 'trigger'
        SettingsHelper.clearCredentials()

  describe 'cloud flash tests', ->
    it 'checks decorators', ->
      spyOn(sparkIde, 'coreRequired').andCallThrough()
      spyOn sparkIde, 'projectRequired'

      sparkIde.flashCloud()
      expect(sparkIde.coreRequired).toHaveBeenCalled()
      expect(sparkIde.projectRequired).not.toHaveBeenCalled()

      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'

      sparkIde.flashCloud()
      expect(sparkIde.projectRequired).toHaveBeenCalled()

      # Cleanup
      jasmine.unspy sparkIde, 'coreRequired'
      jasmine.unspy sparkIde, 'projectRequired'
      SettingsHelper.clearCurrentCore()
      SettingsHelper.clearCredentials()

    it 'tests no firmware files', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      spyOn atom.workspaceView, 'trigger'
      spyOn sparkIde, 'compileCloud'

      sparkIde.flashCloud()
      expect(atom.workspaceView.trigger).toHaveBeenCalled()
      expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-dev:compile-cloud', [true])

      jasmine.unspy sparkIde, 'compileCloud'
      jasmine.unspy atom.workspaceView, 'trigger'
      SettingsHelper.clearCurrentCore()
      SettingsHelper.clearCredentials()

    it 'tests one firmware file', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      originalDeleteFirmwareAfterFlash = atom.config.get 'spark-dev.deleteFirmwareAfterFlash'
      atom.config.set 'spark-dev.deleteFirmwareAfterFlash', false

      atom.config.get('spark-dev.deleteFirmwareAfterFlash')
      fs.openSync atom.project.getPaths()[0] + '/firmware.bin', 'w'
      spyOn sparkIde.statusView, 'setStatus'
      spyOn sparkIde.statusView, 'clearAfter'
      SparkStub.stubSuccess 'flashCore'

      sparkIde.flashCloud()
      expect(sparkIde.statusView.setStatus).toHaveBeenCalled()
      expect(sparkIde.statusView.setStatus).toHaveBeenCalledWith('Flashing via the cloud...')

      waitsFor ->
        !sparkIde.flashCorePromise

      runs ->
        expect(sparkIde.statusView.setStatus).toHaveBeenCalledWith('Update started...')
        expect(sparkIde.statusView.clearAfter).toHaveBeenCalled()
        expect(sparkIde.statusView.clearAfter).toHaveBeenCalledWith(5000)

        # Test removing firmware
        atom.config.set 'spark-dev.deleteFirmwareAfterFlash', false
        sparkIde.flashCloud()
        expect(fs.existsSync(atom.project.getPaths()[0] + '/firmware.bin')).toBe(true)

        jasmine.unspy sparkIde.statusView, 'clearAfter'
        jasmine.unspy sparkIde.statusView, 'setStatus'
        SettingsHelper.clearCurrentCore()
        SettingsHelper.clearCredentials()
        atom.config.set 'spark-dev.deleteFirmwareAfterFlash', originalDeleteFirmwareAfterFlash

    it 'tests passing firmware', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      atom.config.set 'spark-dev.deleteFirmwareAfterFlash', true
      firmwarePath = atom.project.getPaths()[0] + '/firmware.bin'
      SparkStub.stubSuccess 'flashCore'
      fs.openSync firmwarePath, 'w'

      sparkIde.flashCloud 'firmware.bin'
      expect(sparkIde.spark.flashCore).toHaveBeenCalled()
      expect(sparkIde.spark.flashCore).toHaveBeenCalledWith('0123456789abcdef0123456789abcdef', ['firmware.bin'])

      SettingsHelper.clearCurrentCore()
      SettingsHelper.clearCredentials()

    it 'tests more than one firmware file', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      SparkStub.stubSuccess 'flashCore'

      fs.openSync atom.project.getPaths()[0] + '/firmware.bin', 'w'
      fs.openSync atom.project.getPaths()[0] + '/firmware2.bin', 'w'

      sparkIde.initView 'select-firmware'
      spyOn sparkIde.selectFirmwareView, 'setItems'
      spyOn sparkIde.selectFirmwareView, 'show'

      sparkIde.flashCloud()
      expect(sparkIde.selectFirmwareView.setItems).toHaveBeenCalled()
      expect(sparkIde.selectFirmwareView.setItems).toHaveBeenCalledWith([
          atom.project.getPaths()[0] + '/firmware2.bin',
          atom.project.getPaths()[0] + '/firmware.bin'
        ])
      expect(sparkIde.selectFirmwareView.show).toHaveBeenCalled()

      fs.unlinkSync atom.project.getPaths()[0] + '/firmware.bin'
      fs.unlinkSync atom.project.getPaths()[0] + '/firmware2.bin'
      jasmine.unspy sparkIde.selectFirmwareView, 'setItems'
      jasmine.unspy sparkIde.selectFirmwareView, 'show'
      SettingsHelper.clearCurrentCore()
      SettingsHelper.clearCredentials()

  describe 'open pane tests', ->
    url = 'spark-dev://editor/foo'

    describe 'when there already is open panel', ->
      it 'switches to it', ->
        activateItemForUriSpy = jasmine.createSpy 'activateItemForUri'
        spyOn(atom.workspace, 'paneForUri').andReturn {
          activateItemForUri: activateItemForUriSpy
        }

        sparkIde.openPane 'foo'

        expect(atom.workspace.paneForUri).toHaveBeenCalled()
        expect(atom.workspace.paneForUri).toHaveBeenCalledWith(url)
        expect(activateItemForUriSpy).toHaveBeenCalled()
        expect(activateItemForUriSpy).toHaveBeenCalledWith(url)

        jasmine.unspy atom.workspace, 'paneForUri'

    describe 'when there is no panel', ->
      it 'opens new one', ->
        spyOn(atom.workspace, 'paneForUri').andReturn null
        spyOn atom.workspace, 'open'

        # Without splitted panels, split
        spyOn(atom.workspaceView, 'getPaneViews').andReturn ['foo']
        activateSpy = jasmine.createSpy 'activateSpy'
        splitDownSpy = jasmine.createSpy('splitDown').andReturn {
          activate: activateSpy
        }
        spyOn(atom.workspaceView, 'getActivePaneView').andReturn {
          splitDown: splitDownSpy
        }

        sparkIde.openPane 'foo'

        expect(splitDownSpy).toHaveBeenCalled()
        expect(activateSpy).toHaveBeenCalled()
        expect(atom.workspace.open).toHaveBeenCalled()
        expect(atom.workspace.open).toHaveBeenCalledWith(url, {searchAllPanes: true})

        # With splitted panels, use last one
        jasmine.unspy atom.workspaceView, 'getPaneViews'
        splitRightSpy = jasmine.createSpy('splitRight').andReturn {
          activate: activateSpy
        }
        spyOn(atom.workspaceView, 'getPaneViews').andReturn ['foo', {
          splitRight: splitRightSpy
        }]
        activateSpy.reset()
        atom.workspace.open.reset()

        sparkIde.openPane 'foo'

        expect(splitRightSpy).toHaveBeenCalled()
        expect(activateSpy).toHaveBeenCalled()
        expect(atom.workspace.open).toHaveBeenCalled()
        expect(atom.workspace.open).toHaveBeenCalledWith(url, {searchAllPanes: true})

        jasmine.unspy atom.workspaceView, 'getPaneViews'
        jasmine.unspy atom.workspaceView, 'getActivePaneView'
        jasmine.unspy atom.workspace, 'paneForUri'
        jasmine.unspy atom.workspace, 'open'
