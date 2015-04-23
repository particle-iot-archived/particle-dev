SettingsHelper = require '../../lib/utils/settings-helper'

describe 'Serial Monitor View', ->
  activationPromise = null
  originalProfile = null
  sparkIde = null
  workspaceElement = null
  serialMonitorView = null

  initView = ->
    sparkIde.serialMonitorView = null
    sparkIde.initView 'serial-monitor'
    serialMonitorView = sparkIde.serialMonitorView

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

    # Mock serial
    require.cache[require.resolve('serialport')].exports = require('spark-dev-spec-stubs').serialportMultiplePorts

    activationPromise = atom.packages.activatePackage('spark-dev').then ({mainModule}) ->
      sparkIde = mainModule
      initView()

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-dev-test'

    waitsForPromise ->
      activationPromise

  afterEach ->
    SettingsHelper.setProfile originalProfile

  describe '', ->
    beforeEach ->

    afterEach ->

    it 'checks listing ports and baudrates', ->
      # Test ports
      require.cache[require.resolve('serialport')].exports = require('spark-dev-spec-stubs').serialportSuccess
      serialMonitorView.nullifySerialport()

      serialMonitorView.refreshSerialPorts()
      options = serialMonitorView.portsSelect.find 'option'

      expect(options.length).toEqual(1)
      expect(options[0].text).toEqual('/dev/cu.usbmodemfa1234')
      expect(options[0].value).toEqual('/dev/cu.usbmodemfa1234')

      require.cache[require.resolve('serialport')].exports = require('spark-dev-spec-stubs').serialportMultiplePorts
      serialMonitorView.nullifySerialport()
      serialMonitorView.find('#refresh-ports-button').click()

      options = serialMonitorView.portsSelect.find 'option'

      expect(options.length).toEqual(2)
      expect(options[0].text).toEqual('/dev/cu.usbmodemfa1234')
      expect(options[0].value).toEqual('/dev/cu.usbmodemfa1234')

      expect(options[1].text).toEqual('/dev/cu.usbmodemfab1234')
      expect(options[1].value).toEqual('/dev/cu.usbmodemfab1234')

      # Test baudrates
      options = serialMonitorView.baudratesSelect.find 'option'
      expect(options.length).toEqual(12)

      idx = 0
      for baudrate in [300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200]
        expect(options[idx].text).toEqual(baudrate.toString())
        expect(options[idx].value).toEqual(baudrate.toString())
        idx++

      # serialMonitorView.close()

    it 'checks blocking UI on connection', ->
      expect(serialMonitorView.portsSelect.attr('disabled')).toBeUndefined()
      expect(serialMonitorView.refreshPortsButton.attr('disabled')).toBeUndefined()
      expect(serialMonitorView.baudratesSelect.attr('disabled')).toBeUndefined()
      expect(serialMonitorView.connectButton.text()).toEqual('Connect')
      expect(serialMonitorView.input.enabled).toBe(false)

      serialMonitorView.connectButton.click()

      expect(serialMonitorView.portsSelect.attr('disabled')).toEqual('disabled')
      expect(serialMonitorView.refreshPortsButton.attr('disabled')).toEqual('disabled')
      expect(serialMonitorView.baudratesSelect.attr('disabled')).toEqual('disabled')
      expect(serialMonitorView.connectButton.text()).toEqual('Disconnect')
      expect(serialMonitorView.input.enabled).toBe(true)

      serialMonitorView.connectButton.click()

      expect(serialMonitorView.portsSelect.attr('disabled')).toBeUndefined()
      expect(serialMonitorView.refreshPortsButton.attr('disabled')).toBeUndefined()
      expect(serialMonitorView.baudratesSelect.attr('disabled')).toBeUndefined()
      expect(serialMonitorView.connectButton.text()).toEqual('Connect')
      expect(serialMonitorView.input.enabled).toBe(false)

      serialMonitorView.connectButton.click()

      # Test disconnecting on error
      expect(serialMonitorView.connectButton.text()).toEqual('Disconnect')
      spyOn console, 'error'
      serialMonitorView.port.emit 'error'

      expect(serialMonitorView.connectButton.text()).toEqual('Connect')
      expect(console.error).toHaveBeenCalled()

      jasmine.unspy console, 'error'
      # serialMonitorView.close()

    it 'checks serial communication', ->
      serialMonitorView.connectButton.click()

      # Test receiving data
      serialMonitorView.port.emit 'data', 'foo'
      expect(serialMonitorView.output.text()).toEqual('foo')

      # Test sending data
      spyOn serialMonitorView.port, 'write'
      spyOn(serialMonitorView, 'isPortOpen').andReturn true

      serialMonitorView.input.editor.setText 'foo'
      atom.commands.dispatch serialMonitorView.input.editor.element, 'core:confirm'

      expect(serialMonitorView.port.write).toHaveBeenCalled()

      jasmine.unspy serialMonitorView.port, 'write'
      jasmine.unspy serialMonitorView, 'isPortOpen'
      # serialMonitorView.close()

    it 'checks default port and baudrate', ->
      SettingsHelper.set 'serial_port', null
      SettingsHelper.set 'serial_baudrate', null
      initView()

      expect(serialMonitorView.portsSelect.val()).toEqual('/dev/cu.usbmodemfa1234')
      expect(serialMonitorView.baudratesSelect.val()).toEqual('9600')

      SettingsHelper.set 'serial_port', '/dev/cu.usbmodemfab1234'
      SettingsHelper.set 'serial_baudrate', 115200
      initView()

      expect(serialMonitorView.portsSelect.val()).toEqual('/dev/cu.usbmodemfab1234')
      expect(serialMonitorView.baudratesSelect.val()).toEqual('115200')
