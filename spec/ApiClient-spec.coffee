ApiClient = require '../lib/ApiClient'

describe 'Tests for mocked ApiClient library which functions should succeed', ->
  client = null
  promise = null

  beforeEach ->
    ApiClient = require './mocks/ApiClient-success'

    client = new ApiClient 'https://api.spark.io'

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


describe 'Tests for mocked ApiClient library which functions should fail', ->
  client = null
  promise = null

  beforeEach ->
    ApiClient = require './mocks/ApiClient-fail'

    client = new ApiClient 'https://api.spark.io'

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
