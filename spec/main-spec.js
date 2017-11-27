'use babel';
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import _s from 'underscore.string';
import spark from 'spark';
import fs from 'fs-plus';
import whenjs from 'when';
import SettingsHelper from '../lib/utils/settings-helper';
import SerialHelper from '../lib/utils/serial-helper';
import packageName from '../lib/utils/package-helper';
import utilities from '../lib/vendor/utilities';
import { spark as SparkStub } from 'particle-dev-spec-stubs';

let defaultExport = {};
describe('Main Tests', function() {
  let activationPromise = null;
  let main = null;
  let originalProfile = null;
  let workspaceElement = null;

  beforeEach(function() {
    workspaceElement = atom.views.getView(atom.workspace);
    activationPromise = atom.packages.activatePackage(packageName()).then(({mainModule}) => main = mainModule);
      // main.statusView = null

    originalProfile = SettingsHelper.getProfile();
    // For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile('test');
    SettingsHelper.setCredentials();
    atom.project.setPaths([__dirname]);

    return waitsForPromise(() => activationPromise);
  });

  afterEach(() => SettingsHelper.setProfile(originalProfile));


  describe('when the event is triggered, corresponging handler should be called', function() {
    it('calls login() method for :login event', function() {
      spyOn(main, 'login');
      atom.commands.dispatch(workspaceElement, `${packageName()}:login`);
      expect(main.login).toHaveBeenCalled();
      return jasmine.unspy(main, 'login');
    });

    it('calls logout() method for :logout event', function() {
      spyOn(main, 'logout');
      atom.commands.dispatch(workspaceElement, `${packageName()}:logout`);
      expect(main.logout).toHaveBeenCalled();
      return jasmine.unspy(main, 'logout');
    });

    it('calls selectCore() method for :select-device event', function() {
      spyOn(main, 'selectCore');
      atom.commands.dispatch(workspaceElement, `${packageName()}:select-device`);
      expect(main.selectCore).toHaveBeenCalled();
      return jasmine.unspy(main, 'selectCore');
    });

    it('calls renameCore() method for :rename-device event', function() {
      spyOn(main, 'renameCore');
      atom.commands.dispatch(workspaceElement, `${packageName()}:rename-device`);
      expect(main.renameCore).toHaveBeenCalled();
      return jasmine.unspy(main, 'renameCore');
    });

    it('calls removeCore() method for :remove-device event', function() {
      spyOn(main, 'removeCore');
      atom.commands.dispatch(workspaceElement, `${packageName()}:remove-device`);
      expect(main.removeCore).toHaveBeenCalled();
      return jasmine.unspy(main, 'removeCore');
    });

    it('calls claimCore() method for :claim-device event', function() {
      spyOn(main, 'claimCore');
      atom.commands.dispatch(workspaceElement, `${packageName()}:claim-device`);
      expect(main.claimCore).toHaveBeenCalled();
      return jasmine.unspy(main, 'claimCore');
    });

    it('calls identifyCore() method for :identify-device event', function() {
      spyOn(main, 'identifyCore');
      atom.commands.dispatch(workspaceElement, `${packageName()}:identify-device`);
      expect(main.identifyCore).toHaveBeenCalled();
      return jasmine.unspy(main, 'identifyCore');
    });

    it('calls compileCloud() method for :compile-cloud event', function() {
      spyOn(main, 'compileCloud');
      atom.commands.dispatch(workspaceElement, `${packageName()}:compile-cloud`);
      expect(main.compileCloud).toHaveBeenCalled();
      return jasmine.unspy(main, 'compileCloud');
    });

    it('calls showCompileErrors() method for :show-compile-errors event', function() {
      spyOn(main, 'showCompileErrors');
      atom.commands.dispatch(workspaceElement, `${packageName()}:show-compile-errors`);
      expect(main.showCompileErrors).toHaveBeenCalled();
      return jasmine.unspy(main, 'showCompileErrors');
    });

    it('calls flashCloud() method for :flash-cloud event', function() {
      spyOn(main, 'flashCloud');
      atom.commands.dispatch(workspaceElement, `${packageName()}:flash-cloud`);
      expect(main.flashCloud).toHaveBeenCalled();
      return jasmine.unspy(main, 'flashCloud');
    });

    it('calls showSerialMonitor() method for :show-serial-monitor event', function() {
      spyOn(main, 'showSerialMonitor');
      atom.commands.dispatch(workspaceElement, `${packageName()}:show-serial-monitor`);
      expect(main.showSerialMonitor).toHaveBeenCalled();
      return jasmine.unspy(main, 'showSerialMonitor');
    });

    it('calls setupWifi() method for :setup-wifi event', function() {
      spyOn(main, 'setupWifi');
      atom.commands.dispatch(workspaceElement, `${packageName()}:setup-wifi`);
      expect(main.setupWifi).toHaveBeenCalled();
      return jasmine.unspy(main, 'setupWifi');
    });

    return it('calls tryFlashUsb() method for :try-flash-usb event', function() {
      spyOn(main, 'tryFlashUsb');
      atom.commands.dispatch(workspaceElement, `${packageName()}:try-flash-usb`);
      expect(main.tryFlashUsb).toHaveBeenCalled();
      return jasmine.unspy(main, 'tryFlashUsb');
    });
  });


  describe('checks logged out user', function() {
    it('checks :remove-device', function() {
      spyOn(atom, 'confirm');
      main.removeCore();
      expect(atom.confirm).not.toHaveBeenCalled();
      return jasmine.unspy(atom, 'confirm');
    });

    it('does nothing for logged in user without selected core', function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      spyOn(atom, 'confirm');
      main.removeCore();

      expect(atom.confirm).not.toHaveBeenCalled();

      SettingsHelper.clearCredentials();
      return jasmine.unspy(atom, 'confirm');
    });

    return it('asks for confirmation for logged in user with selected core', function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      SettingsHelper.setCurrentCore('0123456789abcdef0123456789abcdef', 'Foo');
      spyOn(atom, 'confirm');
      main.removeCore();

      expect(atom.confirm).toHaveBeenCalled();
      expect(atom.confirm.calls.length).toEqual(1);
      expect(atom.confirm.calls[0].args.length).toEqual(1);
      const args = atom.confirm.calls[0].args[0];

      expect(args.message).toEqual('Removal confirmation');
      expect(args.detailedMessage).toEqual('Do you really want to remove Foo?');
      expect('Cancel' in args.buttons).toEqual(true);
      expect('Remove Foo' in args.buttons).toEqual(true);

      // Test remove callback
      SparkStub.stubSuccess(spark, 'removeCore');

      spyOn(SettingsHelper, 'clearCurrentCore');
      spyOn(atom.commands, 'dispatch');
      args.buttons['Remove Foo']();


      waitsFor(() => !main.removePromise);

      runs(function() {
        expect(SettingsHelper.clearCurrentCore).toHaveBeenCalled();
        expect(atom.commands.dispatch).toHaveBeenCalled();
        expect(atom.commands.dispatch.calls.length).toEqual(2);
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, `${packageName()}:update-core-status`);
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, `${packageName()}:update-menu`);

        // Test fail
        SparkStub.stubFail(spark, 'removeCore');
        return args.buttons['Remove Foo']();
      });

      waitsFor(() => !main.removePromise);

      return runs(function() {
        expect(atom.confirm.calls.length).toEqual(2);
        expect(atom.confirm.calls[1].args.length).toEqual(1);
        const alertArgs = atom.confirm.calls[1].args[0];
        expect(alertArgs.message).toEqual('Error');
        expect(alertArgs.detailedMessage).toEqual('I didn\'t recognize that device name or ID');

        jasmine.unspy(SettingsHelper, 'clearCurrentCore');
        jasmine.unspy(atom.commands, 'dispatch');
        SettingsHelper.clearCurrentCore();
        SettingsHelper.clearCredentials();
        return jasmine.unspy(atom, 'confirm');
      });
    });
  });


  describe('when identifyCore() method is called and there is only one core', () =>
    it('checks if it is identified', function() {
      require('serialport');
      require.cache[require.resolve('serialport')].defaultExport = require('particle-dev-spec-stubs').serialportSuccess;

      spyOn(SerialHelper, 'askForCoreID').andCallThrough();
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');

      main.identifyCore();

      waitsFor(() => !main.listPortsPromise);

      return runs(function() {
        expect(SerialHelper.askForCoreID).toHaveBeenCalled();
        expect(SerialHelper.askForCoreID).toHaveBeenCalledWith('/dev/cu.usbmodemfa1234');
        SettingsHelper.clearCredentials();
        return jasmine.unspy(SerialHelper, 'askForCoreID');
      });
    })
  );


  describe('cloud compile tests', function() {
    it('checks if nothing is done', function() {
      spyOn(main, 'getProjectDir').andReturn(null);

      // For logged out user
      spyOn(SettingsHelper, 'isLoggedIn').andCallThrough();
      main.compileCloud();
      expect(SettingsHelper.isLoggedIn).toHaveBeenCalled();
      expect(main.getProjectDir).not.toHaveBeenCalled();

      // Not null compileCloudPromise
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      spyOn(SettingsHelper, 'set');
      main.compileCloudPromise = 'foo';
      main.compileCloud();
      expect(SettingsHelper.isLoggedIn.calls.length).toEqual(2);
      expect(SettingsHelper.set).not.toHaveBeenCalled();

      // Empty root directory
      main.compileCloudPromise = null;
      main.compileCloud();
      expect(SettingsHelper.isLoggedIn.calls.length).toEqual(3);
      expect(main.getProjectDir).toHaveBeenCalled();
      expect(SettingsHelper.set).not.toHaveBeenCalled();

      // Cleanup
      SettingsHelper.setLocal('compile-status', null);
      jasmine.unspy(SettingsHelper, 'set');
      jasmine.unspy(SettingsHelper, 'isLoggedIn');
      jasmine.unspy(main, 'getProjectDir');
      return SettingsHelper.clearCredentials();
    });

    it('checks if correct files are included', function() {
      const oldPaths = atom.project.getPaths();
      atom.project.setPaths([__dirname + '/data/sampleproject']);
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');

      SparkStub.stubSuccess(spark, 'compileCode');
      this.originalFilesExcludedFromCompile = atom.config.get(`${packageName()}.filesExcludedFromCompile`);
      atom.config.set(`${packageName()}.filesExcludedFromCompile`, '.ds_store, .jpg, .gif, .png, .include, .ignore, Thumbs.db, .git, .bin');

      // main.compileCloud()
      // # Check if local storage is set to working
      // expect(SettingsHelper.getLocal('compile-status')).toEqual({working:true})
      //
      // expect(spark.compileCode).toHaveBeenCalled()
      // expectedFiles = ['lib.h', 'foo.ino', 'inner/bar.cpp', 'lib.cpp']
      // expect(spark.compileCode).toHaveBeenCalledWith(expectedFiles)
      //
      // waitsFor ->
      //   !main.compileCloudPromise
      //
      // runs ->
      //   atom.config.set "#{packageName()}.filesExcludedFromCompile", '.ds_store, .jpg, .ino, .bin'
      //   spark.compileCode.reset()
      //   main.compileCloud()
      //
      //   expect(spark.compileCode).toHaveBeenCalled()
      //   expectedFiles = ['lib.h', 'inner/bar.cpp', 'lib.cpp']
      //   expect(spark.compileCode).toHaveBeenCalledWith(expectedFiles)
      //
      // waitsFor ->
      //   !main.compileCloudPromise
      //
      return runs(function() {
        SettingsHelper.setLocal('compile-status', null);
        SettingsHelper.clearCredentials();
        atom.project.setPaths(oldPaths);
        atom.config.set(`${packageName()}.filesExcludedFromCompile`, this.originalFilesExcludedFromCompile);

        // Remove firmware files
        return (() => {
          const result = [];
          for (let file of Array.from(fs.listSync(__dirname + '/data/sampleproject'))) {
            if (utilities.getFilenameExt(file).toLowerCase() === '.bin') {
              result.push(fs.unlinkSync(file));
            } else {
              result.push(undefined);
            }
          }
          return result;
        })();
      });
    });

    it('checks successful compile', function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      spyOn(main.profileManager.apiClient, 'compileCode').andCallFake(() => {
        return whenjs.resolve({
          body: {
            "ok": true,
            "binary_id": "53fdb4b3a7ce5fe43d3cf079",
            "binary_url": "/v1/binaries/53fdb4b3a7ce5fe43d3cf079",
            "expires_at": "2014-08-28T10:36:35.183Z",
            "sizeInfo": "   text	   data	    bss	    dec	    hex	filename\n  74960	   1236	  11876	  88072	  15808	build/foo.elf\n"
          }
        });
      });
      SparkStub.stubSuccess(spark, 'downloadBinary');

      spyOn(atom.commands, 'dispatch');
      main.compileCloud();

      waitsFor(() => !main.compileCloudPromise);

      waitsFor(() => !main.downloadBinaryPromise);

      runs(function() {
        const compileStatus = SettingsHelper.getLocal('compile-status');
        expect(compileStatus.filename).not.toBeUndefined();
        expect(_s.startsWith(compileStatus.filename, 'core_firmware')).toBe(true);
        expect(_s.endsWith(compileStatus.filename, '.bin')).toBe(true);
        expect(atom.commands.dispatch).toHaveBeenCalled();
        expect(atom.commands.dispatch.calls.length).toEqual(3);
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, `${packageName()}:update-compile-status`);
        expect(atom.commands.dispatch).not.toHaveBeenCalledWith(workspaceElement, `${packageName()}:flash-cloud`);

        // Test leaving old firmwares
        this.originalDeleteOldFirmwareAfterCompile = atom.config.get(`${packageName()}.deleteOldFirmwareAfterCompile`);
        atom.config.set(`${packageName()}.deleteOldFirmwareAfterCompile`, false);
        fs.openSync(atom.project.getPaths()[0] + '/core_firmware_123.bin', 'w');
        return main.compileCloud();
      });

      waitsFor(() => !main.compileCloudPromise);

      waitsFor(() => !main.downloadBinaryPromise);

      runs(function() {
        expect(fs.existsSync(atom.project.getPaths()[0] + '/core_firmware_123.bin')).toBe(true);

        // Test leaving only latest firmware
        atom.config.set(`${packageName()}.deleteOldFirmwareAfterCompile`, true);
        return main.compileCloud();
      });

      waitsFor(() => !main.compileCloudPromise);

      waitsFor(() => !main.downloadBinaryPromise);

      return runs(function() {
        expect(fs.existsSync(atom.project.getPaths()[0] + '/core_firmware_123.bin')).toBe(false);

        SettingsHelper.setLocal('compile-status', null);
        jasmine.unspy(atom.commands, 'dispatch');
        jasmine.unspy(main.profileManager.apiClient, 'compileCode');
        SettingsHelper.clearCredentials();
        return atom.config.set(`${packageName()}.deleteOldFirmwareAfterCompile`, this.originalDeleteOldFirmwareAfterCompile);
      });
    });

    it('checks failed compile', function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      spyOn(main.profileManager.apiClient, 'compileCode').andCallFake(() => {
        return whenjs.reject({
          body: {
            "ok": false,
            "errors": [
              "Blink.cpp: In function 'void setup()':\n"+
              "      Blink.cpp:11:17: error: 'OUTPUTz' was not declared in this scope\n"+
              "       void setup() {\n"+
              "                       ^\n"+
              "      make: *** [Blink.o] Error 1"
            ],
            "output": "App code was invalid",
            "stdout": "Nothing to be done for `all'"
          }
        });
      });
      spyOn(atom.commands, 'dispatch');
      main.compileCloud();

      waitsFor(() => !main.compileCloudPromise);

      return runs(function() {
        const compileStatus = SettingsHelper.getLocal('compile-status');
        expect(compileStatus.errors).not.toBeUndefined();
        expect(compileStatus.errors.length).toEqual(1);

        expect(atom.commands.dispatch).toHaveBeenCalled();
        expect(atom.commands.dispatch.calls.length).toEqual(4);
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, `${packageName()}:update-compile-status`);
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, `${packageName()}:show-compile-errors`);

        SettingsHelper.setLocal('compile-status', null);
        jasmine.unspy(atom.commands, 'dispatch');
        jasmine.unspy(main.profileManager.apiClient, 'compileCode');
        return SettingsHelper.clearCredentials();
      });
    });

    return it('checks flashing after compiling', function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      spyOn(main.profileManager.apiClient, 'compileCode').andCallFake(() => {
        return whenjs.resolve({
          body: {
            "ok": true,
            "binary_id": "53fdb4b3a7ce5fe43d3cf079",
            "binary_url": "/v1/binaries/53fdb4b3a7ce5fe43d3cf079",
            "expires_at": "2014-08-28T10:36:35.183Z",
            "sizeInfo": "   text	   data	    bss	    dec	    hex	filename\n  74960	   1236	  11876	  88072	  15808	build/foo.elf\n"
          }
        });
      });
      SparkStub.stubSuccess(spark, 'downloadBinary');

      spyOn(atom.commands, 'dispatch');
      main.compileCloud(true);

      waitsFor(() => !main.compileCloudPromise);

      waitsFor(() => !main.downloadBinaryPromise);

      return runs(function() {
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, `${packageName()}:flash-cloud`);

        SettingsHelper.setLocal('compile-status', null);
        jasmine.unspy(atom.commands, 'dispatch');
        jasmine.unspy(main.profileManager.apiClient, 'compileCode');
        return SettingsHelper.clearCredentials();
      });
    });
  });

  describe('cloud flash tests', function() {
    it('checks decorators', function() {
      spyOn(main, 'deviceRequired').andCallThrough();
      spyOn(main, 'projectRequired');

      main.flashCloud();
      expect(main.deviceRequired).toHaveBeenCalled();
      expect(main.projectRequired).not.toHaveBeenCalled();

      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      SettingsHelper.setCurrentCore('0123456789abcdef0123456789abcdef', 'Foo');

      main.flashCloud();
      expect(main.projectRequired).toHaveBeenCalled();

      // Cleanup
      jasmine.unspy(main, 'deviceRequired');
      jasmine.unspy(main, 'projectRequired');
      SettingsHelper.clearCurrentCore();
      return SettingsHelper.clearCredentials();
    });

    it('tests no firmware files', function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      SettingsHelper.setCurrentCore('0123456789abcdef0123456789abcdef', 'Foo');
      spyOn(main.emitter, 'emit');
      spyOn(main, 'compileCloud');

      main.flashCloud();
      expect(main.emitter.emit).toHaveBeenCalled();
      expect(main.emitter.emit).toHaveBeenCalledWith(`${packageName()}:compile-cloud`, {thenFlash: true});

      jasmine.unspy(main, 'compileCloud');
      jasmine.unspy(main.emitter, 'emit');
      SettingsHelper.clearCurrentCore();
      return SettingsHelper.clearCredentials();
    });

    it('tests one firmware file', function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      SettingsHelper.setCurrentCore('0123456789abcdef0123456789abcdef', 'Foo');
      const originalDeleteFirmwareAfterFlash = atom.config.get(`${packageName()}.deleteFirmwareAfterFlash`);
      atom.config.set(`${packageName()}.deleteFirmwareAfterFlash`, false);

      atom.config.get(`${packageName()}.deleteFirmwareAfterFlash`);
      fs.openSync(atom.project.getPaths()[0] + '/core_firmware.bin', 'w');
      spyOn(main.statusView, 'setStatus');
      spyOn(main.statusView, 'clearAfter');
      SparkStub.stubSuccess(spark, 'flashCore');

      main.flashCloud();
      expect(main.statusView.setStatus).toHaveBeenCalled();
      expect(main.statusView.setStatus).toHaveBeenCalledWith('Flashing via the cloud...');

      waitsFor(() => !main.flashCorePromise);

      return runs(function() {
        expect(main.statusView.setStatus).toHaveBeenCalledWith('Update started...');
        expect(main.statusView.clearAfter).toHaveBeenCalled();
        expect(main.statusView.clearAfter).toHaveBeenCalledWith(5000);

        // Test removing firmware
        atom.config.set(`${packageName()}.deleteFirmwareAfterFlash`, false);
        main.flashCloud();
        expect(fs.existsSync(atom.project.getPaths()[0] + '/core_firmware.bin')).toBe(true);

        jasmine.unspy(main.statusView, 'clearAfter');
        jasmine.unspy(main.statusView, 'setStatus');
        SettingsHelper.clearCurrentCore();
        SettingsHelper.clearCredentials();
        return atom.config.set(`${packageName()}.deleteFirmwareAfterFlash`, originalDeleteFirmwareAfterFlash);
      });
    });

    it('tests passing firmware', function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      SettingsHelper.setCurrentCore('0123456789abcdef0123456789abcdef', 'Foo');
      atom.config.set(`${packageName()}.deleteFirmwareAfterFlash`, true);
      const firmwarePath = atom.project.getPaths()[0] + '/core_firmware.bin';
      SparkStub.stubSuccess(spark, 'flashCore');
      fs.openSync(firmwarePath, 'w');

      main.flashCloud('core_firmware.bin');
      expect(main.spark.flashCore).toHaveBeenCalled();
      expect(main.spark.flashCore).toHaveBeenCalledWith('0123456789abcdef0123456789abcdef', ['core_firmware.bin']);

      SettingsHelper.clearCurrentCore();
      return SettingsHelper.clearCredentials();
    });

    it('tests more than one firmware file', function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      SettingsHelper.setCurrentCore('0123456789abcdef0123456789abcdef', 'Foo');
      SparkStub.stubSuccess(spark, 'flashCore');

      fs.openSync(atom.project.getPaths()[0] + '/core_firmware.bin', 'w');
      fs.openSync(atom.project.getPaths()[0] + '/core_firmware2.bin', 'w');

      main.initView('select-firmware');
      spyOn(main.selectFirmwareView, 'setItems');
      spyOn(main.selectFirmwareView, 'show');

      main.flashCloud();
      expect(main.selectFirmwareView.setItems).toHaveBeenCalled();
      expect(main.selectFirmwareView.setItems).toHaveBeenCalledWith([
          atom.project.getPaths()[0] + '/core_firmware2.bin',
          atom.project.getPaths()[0] + '/core_firmware.bin'
        ]);
      expect(main.selectFirmwareView.show).toHaveBeenCalled();

      fs.unlinkSync(atom.project.getPaths()[0] + '/core_firmware.bin');
      fs.unlinkSync(atom.project.getPaths()[0] + '/core_firmware2.bin');
      jasmine.unspy(main.selectFirmwareView, 'setItems');
      jasmine.unspy(main.selectFirmwareView, 'show');
      SettingsHelper.clearCurrentCore();
      return SettingsHelper.clearCredentials();
    });

    return it('tests showing error for offline core', function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      SettingsHelper.setCurrentCore('0123456789abcdef0123456789abcdef', 'Foo');
      const firmwarePath = atom.project.getPaths()[0] + '/core_firmware.bin';
      fs.openSync(firmwarePath, 'w');

      SparkStub.stubOffline(spark, 'flashCore');
      spyOn(main.statusView, 'setStatus');

      main.flashCloud('core_firmware.bin');

      waitsFor(() => !main.flashCorePromise);

      return runs(function() {
        expect(main.statusView.setStatus).toHaveBeenCalled();
        expect(main.statusView.setStatus).toHaveBeenCalledWith('Device seems to be offline', 'error');

        jasmine.unspy(main.statusView, 'setStatus');

        fs.unlinkSync(firmwarePath);
        SettingsHelper.clearCurrentCore();
        return SettingsHelper.clearCredentials();
      });
    });
  });

  describe('open pane tests', function() {
    const url = `${packageName()}://editor/foo`;

    describe('when there already is open panel', () =>
      it('switches to it', function() {
        const activateItemForUriSpy = jasmine.createSpy('activateItemForUri');
        spyOn(atom.workspace, 'paneForURI').andReturn({
          activateItemForURI: activateItemForUriSpy});

        main.openPane('foo');

        expect(atom.workspace.paneForURI).toHaveBeenCalled();
        expect(atom.workspace.paneForURI).toHaveBeenCalledWith(url);
        expect(activateItemForUriSpy).toHaveBeenCalled();
        expect(activateItemForUriSpy).toHaveBeenCalledWith(url);

        return jasmine.unspy(atom.workspace, 'paneForURI');
      })
    );

    return describe('when there is no panel', () =>
      it('opens new one', function() {
        spyOn(atom.workspace, 'paneForURI').andReturn(null);
        spyOn(atom.workspace, 'open');

        // Without splitted panels, split
        spyOn(atom.workspace, 'getPanes').andReturn(['foo']);
        const activateSpy = jasmine.createSpy('activateSpy');
        const splitDownSpy = jasmine.createSpy('splitDown').andReturn({
          activate: activateSpy
        });
        spyOn(atom.workspace, 'getActivePane').andReturn({
          splitDown: splitDownSpy
        });

        main.openPane('foo');

        expect(splitDownSpy).toHaveBeenCalled();
        expect(activateSpy).toHaveBeenCalled();
        expect(atom.workspace.open).toHaveBeenCalled();
        expect(atom.workspace.open).toHaveBeenCalledWith(url, {searchAllPanes: true});

        // With splitted panels, use last one
        jasmine.unspy(atom.workspace, 'getPanes');
        const splitRightSpy = jasmine.createSpy('splitRight').andReturn({
          activate: activateSpy
        });
        spyOn(atom.workspace, 'getPanes').andReturn(['foo', {
          splitRight: splitRightSpy
        }]);
        activateSpy.reset();
        atom.workspace.open.reset();

        main.openPane('foo');

        expect(splitRightSpy).toHaveBeenCalled();
        expect(activateSpy).toHaveBeenCalled();
        expect(atom.workspace.open).toHaveBeenCalled();
        expect(atom.workspace.open).toHaveBeenCalledWith(url, {searchAllPanes: true});

        jasmine.unspy(atom.workspace, 'getPanes');
        jasmine.unspy(atom.workspace, 'getActivePane');
        jasmine.unspy(atom.workspace, 'paneForURI');
        return jasmine.unspy(atom.workspace, 'open');
      })
    );
  });

  return describe('isProject tests', () =>
    it('returns true when in project and false if not', function() {
      const oldPaths = atom.project.getPaths();
      atom.project.setPaths([__dirname + '/data/sampleproject']);
      expect(main.isProject()).toBe(true);

      atom.project.setPaths([]);
      expect(main.isProject()).toBe(false);

      atom.project.setPaths(oldPaths);
      return expect(main.isProject()).toBe(false);
    })
  );
});
export default defaultExport;
