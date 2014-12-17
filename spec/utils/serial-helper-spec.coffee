require 'serialport'
require.cache[require.resolve('serialport')].exports = require('spark-dev-spec-stubs').serialportSuccess
SerialHelper = require '../../lib/utils/serial-helper'

describe 'Serial helper tests', ->
  it 'tests listing ports', ->
    promise = SerialHelper.listPorts()

    waitsFor ->
      promise.inspect().state == 'fulfilled'

    runs ->
      status = promise.inspect()
      expect(status.value.length).toBe(1)

  it 'tests listing multiple ports', ->
    require.cache[require.resolve('serialport')].exports = require('spark-dev-spec-stubs').serialportMultiplePorts
    promise = SerialHelper.listPorts()

    waitsFor ->
      promise.inspect().state == 'fulfilled'

    runs ->
      status = promise.inspect()
      expect(status.value.length).toBe(2)

  it 'tests listing no ports', ->
    require.cache[require.resolve('serialport')].exports = require('spark-dev-spec-stubs').serialportNoPorts
    promise = SerialHelper.listPorts()

    waitsFor ->
      promise.inspect().state == 'fulfilled'

    runs ->
      status = promise.inspect()
      expect(status.value.length).toBe(0)

  it 'tests retreiving core ID', ->
    promise = SerialHelper.askForCoreID('foo')

    waitsFor ->
      promise.inspect().state == 'fulfilled'

    runs ->
      status = promise.inspect()
      expect(status.value).toBe('0123456789abcdef0123456789abcdef')

  it 'tests saving WiFi credentials', ->
    promise = SerialHelper.serialWifiConfig('foo', 'ssid', 'pass', 3)

    waitsFor ->
      promise.inspect().state == 'fulfilled'

    runs ->
      status = promise.inspect()
