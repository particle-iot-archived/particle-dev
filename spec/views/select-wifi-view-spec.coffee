{WorkspaceView} = require 'atom'
$ = require('atom').$
SettingsHelper = require '../../lib/utils/settings-helper'

describe 'Select Wifi View', ->
  activationPromise = null
  sparkIde = null
  selectWifiView = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
      sparkIde = mainModule

    originalProfile = SettingsHelper.getProfile()

    # Mock serial
    require.cache[require.resolve('serialport')].exports = require '../stubs/serialport-success'

    waitsForPromise ->
      activationPromise

  describe '', ->
    it 'tests hiding and showing', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      # Test core:cancel
      atom.workspaceView.trigger 'spark-ide:setup-wifi', ['foo']

      runs ->
        expect(atom.workspaceView.find('#spark-ide-select-wifi-view')).toExist()
        atom.workspaceView.trigger 'core:cancel'
        expect(atom.workspaceView.find('#spark-ide-select-wifi-view')).not.toExist()

        # Test core:close
        atom.workspaceView.trigger 'spark-ide:setup-wifi', ['foo']

      runs ->
        expect(atom.workspaceView.find('#spark-ide-select-wifi-view')).toExist()
        atom.workspaceView.trigger 'core:close'
        expect(atom.workspaceView.find('#spark-ide-select-wifi-view')).not.toExist()

        SettingsHelper.clearCredentials()


    fit 'tests loading items', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      sparkIde.initView 'select-wifi'
      selectWifiView = sparkIde.selectWifiView

      spyOn selectWifiView, 'listNetworks'

      atom.workspaceView.trigger 'spark-ide:setup-wifi', ['foo']

      runs ->
        expect(atom.workspaceView.find('#spark-ide-select-wifi-view')).toExist()
        expect(selectWifiView.find('span.loading-message').text()).toEqual('Scaning for networks...')
        expect(selectWifiView.listNetworks).toHaveBeenCalled()

        jasmine.unspy selectWifiView, 'listNetworks'
        SettingsHelper.clearCredentials()
        atom.workspaceView.trigger 'core:close'
