{WorkspaceView} = require 'atom'
$ = require('atom').$
SettingsHelper = require '../../lib/utils/settings-helper'

xdescribe 'Select Port View', ->
  activationPromise = null
  sparkIde = null
  selectPortView = null
  originalProfile = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
      sparkIde = mainModule

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-ide-test'

    # Mock serial
    require.cache[require.resolve('serialport')].exports = require '../mocks/serialport-multiple-ports'

    waitsForPromise ->
      activationPromise

  afterEach ->
    SettingsHelper.setProfile originalProfile

  describe '', ->
    it 'tests hiding and showing', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      # Test core:cancel
      atom.workspaceView.trigger 'spark-ide:identify-core'

      waitsFor ->
        !sparkIde.listPortsPromise

      runs ->
        expect(atom.workspaceView.find('#spark-ide-select-port-view')).toExist()
        atom.workspaceView.trigger 'core:cancel'
        expect(atom.workspaceView.find('#spark-ide-select-port-view')).not.toExist()

        # Test core:close
        atom.workspaceView.trigger 'spark-ide:identify-core'

      waitsFor ->
        !sparkIde.listPortsPromise

      runs ->
        expect(atom.workspaceView.find('#spark-ide-select-port-view')).toExist()
        atom.workspaceView.trigger 'core:close'
        expect(atom.workspaceView.find('#spark-ide-select-port-view')).not.toExist()

        SettingsHelper.clearCredentials()


    it 'tests loading items', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      atom.workspaceView.trigger 'spark-ide:identify-core'

      waitsFor ->
        !sparkIde.listPortsPromise

      runs ->
        selectPortView = sparkIde.selectPortView
        expect(atom.workspaceView.find('#spark-ide-select-port-view')).toExist()

      waitsFor ->
        !selectPortView.listPortsPromise

      runs ->
        devices = selectPortView.find('ol.list-group li')
        expect(devices.length).toEqual(2)

        expect(devices.eq(0).find('.primary-line').text()).toEqual('8D7028785754')
        expect(devices.eq(1).find('.primary-line').text()).toEqual('8D7028785755')

        expect(devices.eq(0).find('.secondary-line').text()).toEqual('/dev/cu.usbmodemfa1234')
        expect(devices.eq(1).find('.secondary-line').text()).toEqual('/dev/cu.usbmodemfab1234')

        SettingsHelper.clearCredentials()
        atom.workspaceView.trigger 'core:close'
