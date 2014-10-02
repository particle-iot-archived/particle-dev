{WorkspaceView} = require 'atom'
$ = require('atom').$
SettingsHelper = require '../../lib/utils/settings-helper'

describe 'Serial Monitor View', ->
  activationPromise = null
  originalProfile = null
  sparkIde = null
  cloudVariablesAndFunctionsView = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView

    # Mock serial
    require.cache[require.resolve('serialport')].exports = require '../stubs/serialport-multiple-ports'

    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
      sparkIde = mainModule
      sparkIde.serialMonitorView = null

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-ide-test'

    waitsForPromise ->
      activationPromise

  afterEach ->
    SettingsHelper.setProfile originalProfile

  describe '', ->
    beforeEach ->

    afterEach ->

    it 'checks hiding and showing', ->
      atom.workspaceView.trigger 'spark-ide:show-serial-monitor'

      waitsFor ->
        !!sparkIde.serialMonitorView && sparkIde.serialMonitorView.hasParent()

      runs ->
        @serialMonitorView = sparkIde.serialMonitorView

        expect(atom.workspaceView.find('#spark-ide-serial-monitor')).toExist()
        @serialMonitorView.close()
        expect(atom.workspaceView.find('#spark-ide-serial-monitor')).not.toExist()

    fit 'checks listing ports and baudrates', ->
      atom.workspaceView.trigger 'spark-ide:show-serial-monitor'

      waitsFor ->
        !!sparkIde.serialMonitorView && sparkIde.serialMonitorView.hasParent()

      runs ->
        @serialMonitorView = sparkIde.serialMonitorView

        # Test ports
        options = @serialMonitorView.portsSelect.find 'option'
        expect(options.length).toEqual(2)
        expect(options[0].text).toEqual('/dev/cu.usbmodemfa1234')
        expect(options[0].value).toEqual('/dev/cu.usbmodemfa1234')

        expect(options[1].text).toEqual('/dev/cu.usbmodemfab1234')
        expect(options[1].value).toEqual('/dev/cu.usbmodemfab1234')
