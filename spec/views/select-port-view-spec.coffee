SettingsHelper = require '../../lib/utils/settings-helper'
SelectPortView = require '../../lib/views/select-port-view'

describe 'Select Port View', ->
  activationPromise = null
  sparkIde = null
  selectPortView = null
  originalProfile = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('spark-dev').then ({mainModule}) ->
      sparkIde = mainModule
      selectPortView = new SelectPortView

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-dev-test'

    # Mock serial
    require.cache[require.resolve('serialport')].exports = require('spark-dev-spec-stubs').serialportMultiplePorts

    waitsForPromise ->
      activationPromise

  afterEach ->
    SettingsHelper.setProfile originalProfile

  describe '', ->
    it 'tests loading items', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      selectPortView.show()

      waitsFor ->
        !selectPortView.listPortsPromise

      runs ->
        devices = selectPortView.find('ol.list-group li')
        expect(devices.length).toEqual(2)

        expect(devices.eq(0).find('.primary-line').text()).toEqual('8D7028785754')
        expect(devices.eq(1).find('.primary-line').text()).toEqual('8D7028785755')

        expect(devices.eq(0).find('.secondary-line').text()).toEqual('/dev/cu.usbmodemfa1234')
        expect(devices.eq(1).find('.secondary-line').text()).toEqual('/dev/cu.usbmodemfab1234')

        selectPortView.hide()
        SettingsHelper.clearCredentials()
