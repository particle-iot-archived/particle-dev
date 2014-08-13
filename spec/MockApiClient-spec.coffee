ApiClient = require '../lib/vendor/ApiClient'
apiUrl = 'http://example.com'

describe 'Tests for mocked ApiClient library which functions should succeed', ->
  client = null
  promise = null

  beforeEach ->
    ApiClient = require './mocks/ApiClient-success'

    client = new ApiClient apiUrl

    jasmine.unspy(window, 'setTimeout')


  it 'passes fake credentials', ->
    promise = client.login 'spark-ide', 'foo@bar.com', 'pass'

    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      expect(promise.inspect().state).toBe('fulfilled')


  it 'lists devices', ->
    promise = client.listDevices()

    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      status = promise.inspect()
      expect(status.state).toBe('fulfilled')
      expect(status.value).not.toBe(null)
      # There should be 2 devices, one connected and one not
      expect(status.value.length).toBe(2)
      expect(status.value[0].connected).toBe(true)
      expect(status.value[1].connected).toBe(false)


  it 'gets device attributes', ->
    promise = client.getAttributes('51ff6e065067545724680187')

    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      status = promise.inspect()
      expect(status.state).toBe('fulfilled')
      expect(status.value).not.toBe(null)

      expect(status.value.id).toBe('51ff6e065067545724680187')
      expect(status.value.name).toBe('Online Core')
      expect(status.value.connected).toBe(true)

      expect(typeof status.value.variables).toBe('object')
      expect(Object.keys(status.value.variables).length).toBe(0)
      expect(status.value.functions instanceof Array).toBe(true)
      expect(status.value.functions.length).toBe(0)


describe 'Tests for mocked ApiClient library which functions should fail', ->
  client = null
  promise = null

  beforeEach ->
    ApiClient = require './mocks/ApiClient-fail'

    client = new ApiClient apiUrl

    jasmine.unspy(window, 'setTimeout')

  it 'passes fake credentials', ->
    promise = client.login 'spark-ide', 'foo@bar.com', 'pass'
    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      expect(promise.inspect().state).toBe('rejected')

  it 'lists devices', ->
    promise = client.listDevices()

    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      status = promise.inspect()
      expect(status.state).toBe('fulfilled')
      expect(status.value).not.toBe(null)
      expect(status.value.code).toBe(400)


  it 'gets device attributes', ->
    promise = client.getAttributes('51ff6e065067545724680187')

    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      status = promise.inspect()
      expect(status.state).toBe('fulfilled')
      expect(status.value).not.toBe(null)

      expect(status.value.error).toBe('Permission Denied')
      expect(status.value.info).toBe('I didn\'t recognize that core name or ID')


describe 'Tests for mocked ApiClient library with devices which should be offline', ->
  client = null
  promise = null

  beforeEach ->
    ApiClient = require './mocks/ApiClient-offline'

    client = new ApiClient apiUrl

    jasmine.unspy(window, 'setTimeout')

  it 'lists devices', ->
    promise = client.listDevices()

    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      status = promise.inspect()
      expect(status.state).toBe('fulfilled')
      expect(status.value).not.toBe(null)
      # There should be 2 devices, one connected and one not
      expect(status.value.length).toBe(2)
      expect(status.value[0].connected).toBe(false)
      expect(status.value[1].connected).toBe(false)

  it 'gets device attributes', ->
    promise = client.getAttributes('51ff6e065067545724680187')

    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      status = promise.inspect()
      expect(status.state).toBe('fulfilled')
      expect(status.value).not.toBe(null)

      expect(status.value.id).toBe('51ff6e065067545724680187')
      expect(status.value.name).toBe('Online Core')
      expect(status.value.connected).toBe(false)

      expect(typeof status.value.variables).toBe('object')
      expect(Object.keys(status.value.variables).length).toBe(0)
      expect(status.value.functions instanceof Array).toBe(true)
      expect(status.value.functions.length).toBe(0)
