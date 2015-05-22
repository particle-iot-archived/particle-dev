SettingsHelper = require '../../lib/utils/settings-helper'
SparkStub = require('spark-dev-spec-stubs').spark
spark = require 'spark'

describe 'Select Core View', ->
  activationPromise = null
  selectCoreView = null
  originalProfile = null
  sparkIde = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('spark-dev').then ({mainModule}) ->
      sparkIde = mainModule
      sparkIde.selectCoreView = null
      SparkStub.stubSuccess spark, 'listDevices'
      sparkIde.initView 'select-core'
      selectCoreView = sparkIde.selectCoreView
      selectCoreView.spark = require 'spark'
      selectCoreView.spark.login
        accessToken: '0123456789abcdef0123456789abcdef'
      selectCoreView.requestErrorHandler = ->

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-dev-test'

    waitsForPromise ->
      activationPromise

  afterEach ->
    SettingsHelper.setProfile originalProfile

  describe '', ->
    it 'tests loading items', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      selectCoreView.show()

      expect(selectCoreView.find('div.loading').css('display')).toEqual('block')
      expect(selectCoreView.find('span.loading-message').text()).toEqual('Loading devices...')
      expect(selectCoreView.find('ol.list-group li').length).toEqual(0)

      waitsFor ->
        !selectCoreView.listDevicesPromise

      runs ->
        devices = selectCoreView.find('ol.list-group li')
        expect(devices.length).toEqual(3)

        expect(devices.eq(0).find('.primary-line').hasClass('core-online')).toEqual(true)
        expect(devices.eq(1).find('.primary-line').hasClass('core-offline')).toEqual(true)
        expect(devices.eq(2).find('.primary-line').hasClass('core-offline')).toEqual(true)

        expect(devices.eq(0).find('.primary-line').text()).toEqual('Online Core')
        expect(devices.eq(1).find('.primary-line').text()).toEqual('Offline Core')
        expect(devices.eq(2).find('.primary-line').text()).toEqual('Unnamed')

        expect(devices.eq(0).find('.secondary-line').text()).toEqual('51ff6e065067545724680187')
        expect(devices.eq(1).find('.secondary-line').text()).toEqual('51ff67258067545724380687')
        expect(devices.eq(2).find('.secondary-line').text()).toEqual('51ff61258067545724380687')

        selectCoreView.hide()
        SettingsHelper.clearCredentials()

    it 'tests choosing core', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      selectCoreView.show()

      waitsFor ->
        !selectCoreView.listDevicesPromise

      runs ->
        spyOn SettingsHelper, 'setCurrentCore'
        spyOn atom.commands, 'dispatch'
        devices = selectCoreView.find('ol.list-group li')
        devices.eq(0).addClass 'selected'

        selectCoreView.confirmed selectCoreView.items[0]

        expect(SettingsHelper.setCurrentCore).toHaveBeenCalled()
        expect(SettingsHelper.setCurrentCore).toHaveBeenCalledWith('51ff6e065067545724680187', 'Online Core', 0)
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, 'spark-dev:update-core-status')
        expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, 'spark-dev:update-menu')

        jasmine.unspy atom.commands, 'dispatch'
        jasmine.unspy SettingsHelper, 'setCurrentCore'
        SettingsHelper.clearCredentials()
