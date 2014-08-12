{WorkspaceView} = require 'atom'
$ = require('atom').$
SettingsHelper = require '../lib/utils/settings-helper'

describe 'Select Core View Tests', ->
  activationPromise = null
  coresView = null
  originalProfile = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
      coresView = mainModule.coresView

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-ide-test'

    # Mock ApiClient
    require '../lib/vendor/ApiClient'
    require.cache[require.resolve('../lib/vendor/ApiClient')].exports = require './mocks/ApiClient-success'

    atom.workspaceView.trigger 'spark-ide:select-core'

  afterEach ->
    SettingsHelper.setProfile originalProfile


  it 'tests hiding and showing', ->
    waitsForPromise ->
      activationPromise

    runs ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      # Test core:cancel
      atom.workspaceView.trigger 'spark-ide:select-core'
      expect(atom.workspaceView.find('#spark-ide-cores-view')).toExist()
      atom.workspaceView.trigger 'core:cancel'
      expect(atom.workspaceView.find('#spark-ide-cores-view')).not.toExist()

      # Test core:close
      atom.workspaceView.trigger 'spark-ide:select-core'
      expect(atom.workspaceView.find('#spark-ide-cores-view')).toExist()
      atom.workspaceView.trigger 'core:close'
      expect(atom.workspaceView.find('#spark-ide-cores-view')).not.toExist()

      SettingsHelper.clearCredentials()


  it 'tests loading items', ->
    waitsForPromise ->
      activationPromise

    runs ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      atom.workspaceView.trigger 'spark-ide:select-core'

      expect(atom.workspaceView.find('#spark-ide-cores-view')).toExist()
      expect(coresView.find('div.loading').css('display')).toEqual('block')
      expect(coresView.find('span.loading-message').text()).toEqual('Loading cores...')
      expect(coresView.find('ol.list-group li').length).toEqual(0)

    waitsFor ->
      !coresView.listDevicesPromise

    runs ->
      devices = coresView.find('ol.list-group li')
      expect(devices.length).toEqual(2)
      expect(devices.eq(0).find('.primary-line').hasClass('core-online')).toEqual(true)
      expect(devices.eq(1).find('.primary-line').hasClass('core-offline')).toEqual(true)

      expect(devices.eq(0).find('.primary-line').text()).toEqual('Online Core')
      expect(devices.eq(1).find('.primary-line').text()).toEqual('Offline Core')

      expect(devices.eq(0).find('.secondary-line').text()).toEqual('51ff6e065067545724680187')
      expect(devices.eq(1).find('.secondary-line').text()).toEqual('51ff67258067545724380687')

      SettingsHelper.clearCredentials()
      atom.workspaceView.trigger 'core:close'
