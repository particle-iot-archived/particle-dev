{WorkspaceView} = require 'atom'
_s = require 'underscore.string'
spark = require 'spark'
fs = require 'fs-plus'
SettingsHelper = require '../lib/utils/settings-helper'
SerialHelper = require '../lib/utils/serial-helper'
utilities = require '../lib/vendor/utilities'
SparkStub = require './stubs/spark'

fdescribe 'Main Tests', ->
  activationPromise = null
  sparkIde = null
  originalProfile = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
      sparkIde = mainModule
      # sparkIde.statusView = null

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

    it 'calls showCloudVariablesAndFunctions() method for spark-ide:show-cloud-variables-and-functions event', ->
      spyOn sparkIde, 'showCloudVariablesAndFunctions'
      atom.workspaceView.trigger 'spark-ide:show-cloud-variables-and-functions'
      expect(sparkIde.showCloudVariablesAndFunctions).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'showCloudVariablesAndFunctions'

    it 'calls flashCloud() method for spark-ide:flash-cloud event', ->
      spyOn sparkIde, 'flashCloud'
      atom.workspaceView.trigger 'spark-ide:flash-cloud'
      expect(sparkIde.flashCloud).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'flashCloud'

    it 'calls flashCloud() method for spark-ide:flash-cloud event', ->
      spyOn sparkIde, 'flashCloud'
      atom.workspaceView.trigger 'spark-ide:flash-cloud'
      expect(sparkIde.flashCloud).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'flashCloud'

    it 'calls showSerialMonitor() method for spark-ide:show-serial-monitor event', ->
      spyOn sparkIde, 'showSerialMonitor'
      atom.workspaceView.trigger 'spark-ide:show-serial-monitor'
      expect(sparkIde.showSerialMonitor).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'showSerialMonitor'

    it 'calls setupWifi() method for spark-ide:setup-wifi event', ->
      spyOn sparkIde, 'setupWifi'
      atom.workspaceView.trigger 'spark-ide:setup-wifi'
      expect(sparkIde.setupWifi).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'setupWifi'


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
        expect(alertArgs.message).toEqual('Error')
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
      spyOn(atom.project, 'getPaths').andReturn []

      # For logged out user
      spyOn(SettingsHelper, 'isLoggedIn').andCallThrough()
      atom.workspaceView.trigger 'spark-ide:compile-cloud'
      expect(SettingsHelper.isLoggedIn).toHaveBeenCalled()
      expect(atom.project.getPaths).not.toHaveBeenCalled()

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
      atom.workspaceView.trigger 'spark-ide:compile-cloud'
      # Check if local storage is set to working
      expect(SettingsHelper.get('compile-status')).toEqual({working:true})

      expect(spark.compileCode).toHaveBeenCalled()

      expectedFiles = ['foo.ino', 'lib.cpp', 'lib.h']

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
        expect(atom.workspaceView.trigger).not.toHaveBeenCalledWith('spark-ide:flash-cloud')

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

    it 'checks flashing after compiling', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SparkStub.stubSuccess 'compileCode'
      SparkStub.stubSuccess 'downloadBinary'

      atom.workspaceView.trigger 'spark-ide:compile-cloud', [true]
      spyOn atom.workspaceView, 'trigger'

      waitsFor ->
        !sparkIde.compileCloudPromise

      waitsFor ->
        !sparkIde.downloadBinaryPromise

      runs ->
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-ide:flash-cloud')

        SettingsHelper.set 'compile-status', null
        jasmine.unspy atom.workspaceView, 'trigger'
        SettingsHelper.clearCredentials()

  describe 'cloud flash tests', ->
    it 'checks decorators', ->
      spyOn(sparkIde, 'coreRequired').andCallThrough()
      spyOn sparkIde, 'projectRequired'

      atom.workspaceView.trigger 'spark-ide:flash-cloud'
      expect(sparkIde.coreRequired).toHaveBeenCalled()
      expect(sparkIde.projectRequired).not.toHaveBeenCalled()

      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'

      atom.workspaceView.trigger 'spark-ide:flash-cloud'
      expect(sparkIde.projectRequired).toHaveBeenCalled()

      # Cleanup
      jasmine.unspy sparkIde, 'coreRequired'
      jasmine.unspy sparkIde, 'projectRequired'
      SettingsHelper.clearCurrentCore()
      SettingsHelper.clearCredentials()

    it 'tests no firmware files', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      spyOn(atom.workspaceView, 'trigger').andCallThrough()
      spyOn sparkIde, 'compileCloud'

      atom.workspaceView.trigger 'spark-ide:flash-cloud'
      expect(atom.workspaceView.trigger).toHaveBeenCalled()
      expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-ide:compile-cloud', [true])

      jasmine.unspy sparkIde, 'compileCloud'
      jasmine.unspy atom.workspaceView, 'trigger'
      SettingsHelper.clearCurrentCore()
      SettingsHelper.clearCredentials()

    it 'tests one firmware file', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      originalDeleteFirmwareAfterFlash = atom.config.get 'spark-ide.deleteFirmwareAfterFlash'
      atom.config.set 'spark-ide.deleteFirmwareAfterFlash', false

      atom.config.get('spark-ide.deleteFirmwareAfterFlash')
      fs.openSync atom.project.getPaths()[0] + '/firmware.bin', 'w'
      spyOn sparkIde.statusView, 'setStatus'
      spyOn sparkIde.statusView, 'clearAfter'
      SparkStub.stubSuccess 'flashCore'

      atom.workspaceView.trigger 'spark-ide:flash-cloud'
      expect(sparkIde.statusView.setStatus).toHaveBeenCalled()
      expect(sparkIde.statusView.setStatus).toHaveBeenCalledWith('Flashing via the cloud...')

      waitsFor ->
        !sparkIde.flashCorePromise

      runs ->
        expect(sparkIde.statusView.setStatus).toHaveBeenCalledWith('Update started...')
        expect(sparkIde.statusView.clearAfter).toHaveBeenCalled()
        expect(sparkIde.statusView.clearAfter).toHaveBeenCalledWith(5000)

        # Test removing firmware
        atom.config.set 'spark-ide.deleteFirmwareAfterFlash', false
        atom.workspaceView.trigger 'spark-ide:flash-cloud'
        expect(fs.existsSync(atom.project.getPaths()[0] + '/firmware.bin')).toBe(true)

        jasmine.unspy sparkIde.statusView, 'clearAfter'
        jasmine.unspy sparkIde.statusView, 'setStatus'
        SettingsHelper.clearCurrentCore()
        SettingsHelper.clearCredentials()
        atom.config.set 'spark-ide.deleteFirmwareAfterFlash', originalDeleteFirmwareAfterFlash

    it 'tests passing firmware', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      SparkStub.stubSuccess 'flashCore'
      fs.openSync atom.project.getPaths()[0] + '/firmware.bin', 'w'

      atom.workspaceView.trigger 'spark-ide:flash-cloud', ['firmware2.bin']
      expect(sparkIde.spark.flashCore).toHaveBeenCalled()
      expect(sparkIde.spark.flashCore).toHaveBeenCalledWith('0123456789abcdef0123456789abcdef', ['firmware2.bin'])

      fs.unlinkSync atom.project.getPaths()[0] + '/firmware.bin'
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

      atom.workspaceView.trigger 'spark-ide:flash-cloud'
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
    url = 'spark-ide://editor/foo'

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
