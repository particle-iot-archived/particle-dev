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

    it 'checks listing ports and baudrates', ->
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

        # Test baudrates
        options = @serialMonitorView.baudratesSelect.find 'option'
        expect(options.length).toEqual(12)

        idx = 0
        for baudrate in [300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200]
          expect(options[idx].text).toEqual(baudrate.toString())
          expect(options[idx].value).toEqual(baudrate.toString())
          idx++

        @serialMonitorView.close()

    it 'checks blocking UI on connection', ->
      atom.workspaceView.trigger 'spark-ide:show-serial-monitor'

      waitsFor ->
        !!sparkIde.serialMonitorView && sparkIde.serialMonitorView.hasParent()

      runs ->
        @serialMonitorView = sparkIde.serialMonitorView

        expect(@serialMonitorView.portsSelect.attr('disabled')).toBeUndefined()
        expect(@serialMonitorView.baudratesSelect.attr('disabled')).toBeUndefined()
        expect(@serialMonitorView.connectButton.text()).toEqual('Connect')
        expect(@serialMonitorView.input.hiddenInput.attr('disabled')).toEqual('disabled')

        @serialMonitorView.connectButton.click()

        expect(@serialMonitorView.portsSelect.attr('disabled')).toEqual('disabled')
        expect(@serialMonitorView.baudratesSelect.attr('disabled')).toEqual('disabled')
        expect(@serialMonitorView.connectButton.text()).toEqual('Disconnect')
        expect(@serialMonitorView.input.hiddenInput.attr('disabled')).toBeUndefined()

        @serialMonitorView.port.emit 'error'

        expect(@serialMonitorView.connectButton.text()).toEqual('Connect')

        @serialMonitorView.close()

    it 'checks serial communication', ->
      atom.workspaceView.trigger 'spark-ide:show-serial-monitor'

      waitsFor ->
        !!sparkIde.serialMonitorView && sparkIde.serialMonitorView.hasParent()

      runs ->
        @serialMonitorView = sparkIde.serialMonitorView

        @serialMonitorView.connectButton.click()

        # Test receiving data
        @serialMonitorView.port.emit 'data', 'foo'
        expect(@serialMonitorView.output.text()).toEqual('foo')

        # Test sending data
        spyOn @serialMonitorView.port, 'write'
        spyOn(@serialMonitorView, 'isPortOpen').andReturn true

        @serialMonitorView.input.setText 'foo'
        event = $.Event 'keydown'
        event.which = 13
        @serialMonitorView.input.hiddenInput.trigger event
        expect(@serialMonitorView.port.write).toHaveBeenCalled()

        jasmine.unspy @serialMonitorView.port, 'write'
        jasmine.unspy @serialMonitorView, 'isPortOpen'
        @serialMonitorView.close()

    it 'checks default port and baudrate', ->
      SettingsHelper.set 'serial_port', null
      SettingsHelper.set 'serial_baudrate', null

      atom.workspaceView.trigger 'spark-ide:show-serial-monitor'

      waitsFor ->
        !!sparkIde.serialMonitorView && sparkIde.serialMonitorView.hasParent()

      runs ->
        @serialMonitorView = sparkIde.serialMonitorView

        expect(@serialMonitorView.portsSelect.val()).toEqual('/dev/cu.usbmodemfa1234')
        expect(@serialMonitorView.baudratesSelect.val()).toEqual('9600')

        SettingsHelper.set 'serial_port', '/dev/cu.usbmodemfab1234'
        SettingsHelper.set 'serial_baudrate', 115200

        @serialMonitorView.close()
        sparkIde.serialMonitorView == null

        atom.workspaceView.trigger 'spark-ide:show-serial-monitor'

      waitsFor ->
        !!sparkIde.serialMonitorView && sparkIde.serialMonitorView.hasParent()

      runs ->
        @serialMonitorView = sparkIde.serialMonitorView

        expect(@serialMonitorView.portsSelect.val()).toEqual('/dev/cu.usbmodemfab1234')
        expect(@serialMonitorView.baudratesSelect.val()).toEqual('115200')

        @serialMonitorView.close()
