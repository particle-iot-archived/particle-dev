'use babel';
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import SettingsHelper from '../../lib/utils/settings-helper';
import packageName from '../../lib/utils/package-helper';
import { spark as SparkStub } from 'particle-dev-spec-stubs';
import spark from 'spark';

describe('Select Core View', function() {
  let activationPromise = null;
  let selectCoreView = null;
  let originalProfile = null;
  let main = null;
  let workspaceElement = null;

  beforeEach(function() {
    workspaceElement = atom.views.getView(atom.workspace);
    activationPromise = atom.packages.activatePackage(packageName()).then(function({mainModule}) {
      main = mainModule;
      main.selectCoreView = null;
      SparkStub.stubSuccess(spark, 'listDevices');
      main.initView('select-core');
      ({ selectCoreView } = main);
      selectCoreView.spark = require('spark');
      selectCoreView.spark.login({
        accessToken: '0123456789abcdef0123456789abcdef'});
      return selectCoreView.requestErrorHandler = function() {};
    });

    originalProfile = SettingsHelper.getProfile();
    // For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile('test');

    return waitsForPromise(() => activationPromise);
  });

  afterEach(() => SettingsHelper.setProfile(originalProfile));

  return describe('', function() {
    it('tests loading items', function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      selectCoreView.show();

      expect(selectCoreView.find('div.loading').css('display')).toEqual('block');
      expect(selectCoreView.find('span.loading-message').text()).toEqual('Loading devices...');
      expect(selectCoreView.find('ol.list-group li').length).toEqual(0);

      waitsFor(() => !selectCoreView.listDevicesPromise);

      return runs(function() {
        const devices = selectCoreView.find('ol.list-group li');
        expect(devices.length).toEqual(3);

        expect(devices.eq(0).find('.primary-line').hasClass('core-online')).toEqual(true);
        expect(devices.eq(1).find('.primary-line').hasClass('core-offline')).toEqual(true);
        expect(devices.eq(2).find('.primary-line').hasClass('core-offline')).toEqual(true);

        expect(devices.eq(0).find('.primary-line').text()).toEqual('Online Core');
        expect(devices.eq(1).find('.primary-line').text()).toEqual('Offline Core');
        expect(devices.eq(2).find('.primary-line').text()).toEqual('Unnamed');

        expect(devices.eq(0).find('.secondary-line').text()).toEqual('51ff6e065067545724680187');
        expect(devices.eq(1).find('.secondary-line').text()).toEqual('51ff67258067545724380687');
        expect(devices.eq(2).find('.secondary-line').text()).toEqual('51ff61258067545724380687');

        selectCoreView.hide();
        return SettingsHelper.clearCredentials();
      });
    });

    return it('tests choosing core', function() {
      SettingsHelper.setCredentials('foo@bar.baz', '0123456789abcdef0123456789abcdef');
      selectCoreView.show();

      waitsFor(() => !selectCoreView.listDevicesPromise);

      return runs(function() {
        spyOn(SettingsHelper, 'setCurrentCore');
        spyOn(atom.commands, 'dispatch');
        const devices = selectCoreView.find('ol.list-group li');
        devices.eq(0).addClass('selected');

        selectCoreView.confirmed(selectCoreView.items[0]);

        expect(SettingsHelper.setCurrentCore).toHaveBeenCalled();
        expect(SettingsHelper.setCurrentCore).toHaveBeenCalledWith('51ff6e065067545724680187', 'Online Core', 0);
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, `${packageName()}:update-core-status`);
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, `${packageName()}:update-menu`);

        jasmine.unspy(atom.commands, 'dispatch');
        jasmine.unspy(SettingsHelper, 'setCurrentCore');
        return SettingsHelper.clearCredentials();
      });
    });
  });
});
