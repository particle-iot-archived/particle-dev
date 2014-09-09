{WorkspaceView} = require 'atom'
$ = require('atom').$
SettingsHelper = require '../../lib/utils/settings-helper'

describe 'Select Core View', ->
  activationPromise = null
  selectCoreView = null
  originalProfile = null
  sparkIde = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
      sparkIde = mainModule

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-ide-test'

    # Mock ApiClient
    require '../../lib/vendor/ApiClient'
    require.cache[require.resolve('../../lib/vendor/ApiClient')].exports = require '../mocks/ApiClient-success'

    waitsForPromise ->
      activationPromise

  afterEach ->
    SettingsHelper.setProfile originalProfile

  describe '', ->
    it 'tests hiding and showing', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      # Test core:cancel
      atom.workspaceView.trigger 'spark-ide:select-core'
      expect(atom.workspaceView.find('#spark-ide-select-core-view')).toExist()
      atom.workspaceView.trigger 'core:cancel'
      expect(atom.workspaceView.find('#spark-ide-select-core-view')).not.toExist()

      # Test core:close
      atom.workspaceView.trigger 'spark-ide:select-core'
      expect(atom.workspaceView.find('#spark-ide-select-core-view')).toExist()
      atom.workspaceView.trigger 'core:close'
      expect(atom.workspaceView.find('#spark-ide-select-core-view')).not.toExist()

      SettingsHelper.clearCredentials()


    it 'tests loading items', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      atom.workspaceView.trigger 'spark-ide:select-core'
      selectCoreView = sparkIde.selectCoreView

      expect(atom.workspaceView.find('#spark-ide-select-core-view')).toExist()
      expect(selectCoreView.find('div.loading').css('display')).toEqual('block')
      expect(selectCoreView.find('span.loading-message').text()).toEqual('Loading cores...')
      expect(selectCoreView.find('ol.list-group li').length).toEqual(0)

      waitsFor ->
        !selectCoreView.listDevicesPromise

      runs ->
        devices = selectCoreView.find('ol.list-group li')
        expect(devices.length).toEqual(2)
        expect(devices.eq(0).find('.primary-line').hasClass('core-online')).toEqual(true)
        expect(devices.eq(1).find('.primary-line').hasClass('core-offline')).toEqual(true)

        expect(devices.eq(0).find('.primary-line').text()).toEqual('Online Core')
        expect(devices.eq(1).find('.primary-line').text()).toEqual('Offline Core')

        expect(devices.eq(0).find('.secondary-line').text()).toEqual('51ff6e065067545724680187')
        expect(devices.eq(1).find('.secondary-line').text()).toEqual('51ff67258067545724380687')

        SettingsHelper.clearCredentials()
        atom.workspaceView.trigger 'core:close'

    fit 'tests choosing core', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      atom.workspaceView.trigger 'spark-ide:select-core'
      selectCoreView = sparkIde.selectCoreView

      waitsFor ->
        !selectCoreView.listDevicesPromise

      runs ->
        spyOn SettingsHelper, 'setCurrentCore'
        spyOn atom.workspaceView, 'trigger'
        devices = selectCoreView.find('ol.list-group li')
        devices.eq(0).addClass 'selected'
        selectCoreView.trigger 'core:confirm'

        expect(SettingsHelper.setCurrentCore).toHaveBeenCalled()
        expect(SettingsHelper.setCurrentCore).toHaveBeenCalledWith('51ff6e065067545724680187', 'Online Core')
        expect(atom.workspaceView.trigger).toHaveBeenCalled()
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-ide:update-core-status')
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-ide:update-menu')

        jasmine.unspy atom.workspaceView, 'trigger'
        jasmine.unspy SettingsHelper, 'setCurrentCore'
        SettingsHelper.clearCredentials()
