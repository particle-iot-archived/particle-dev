ApiClient = require '../lib/vendor/ApiClient'
apiUrl = 'http://example.com'

describe 'Tests for mocked ApiClient library which functions should succeed', ->
  client = null
  promise = null

  beforeEach ->
    ApiClient = require './mocks/ApiClient-success'

    client = new ApiClient apiUrl

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


  it 'renames core', ->
    promise = client.renameCore('51ff6e065067545724680187', 'Bar')

    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      status = promise.inspect()
      expect(status.state).toBe('fulfilled')
      expect(status.value).not.toBe(null)

      expect(status.value.id).toBe('51ff6e065067545724680187')
      expect(status.value.name).toBe('Bar')

  it 'removes core', ->
    promise = client.removeCore('51ff6e065067545724680187')

    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      status = promise.inspect()
      expect(status.state).toBe('fulfilled')
      expect(status.value).not.toBe(null)

      expect(status.value.ok).toBe(true)

  it 'claims core', ->
    promise = client.claimCore('51ff6e065067545724680187')

    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      status = promise.inspect()
      expect(status.state).toBe('fulfilled')
      expect(status.value).not.toBe(null)

      expect(status.value.user_id).toBe('53187f78907210fed300048f')
      expect(status.value.id).toBe('51ff6e065067545724680187')
      expect(status.value.connected).toBe(true)
      expect(status.value.ok).toBe(true)

  it 'compiles a file', ->
    promise = client.compileCode(['foo.ino'])

    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      status = promise.inspect()
      expect(status.state).toBe('fulfilled')
      expect(status.value).not.toBe(null)

      expect(status.value.binary_id).toBe('53fdb4b3a7ce5fe43d3cf079')
      expect(status.value.binary_url).toBe('/v1/binaries/53fdb4b3a7ce5fe43d3cf079')
      expect(status.value.expires_at).toBe('2014-08-28T10:36:35.183Z')
      expect(status.value.ok).toBe(true)
      expect(status.value.sizeInfo).toBe("   text	   data	    bss	    dec	    hex	filename\n  74960	   1236	  11876	  88072	  15808	build/foo.elf\n")

describe 'Tests for mocked ApiClient library which functions should fail', ->
  client = null
  promise = null

  beforeEach ->
    ApiClient = require './mocks/ApiClient-fail'

    client = new ApiClient apiUrl

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

  it 'renames core', ->
    promise = client.renameCore('51ff6e065067545724680187')

    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      status = promise.inspect()
      expect(status.state).toBe('rejected')
      expect(status.reason).not.toBe(null)

      expect(status.reason.error).toBe('Permission Denied')
      expect(status.reason.info).toBe('I didn\'t recognize that core name or ID')

  it 'removes core', ->
    promise = client.removeCore('51ff6e065067545724680187')

    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      status = promise.inspect()
      expect(status.state).toBe('rejected')
      expect(status.reason).not.toBe(null)

      expect(status.reason.error).toBe('Permission Denied')
      expect(status.reason.info).toBe('I didn\'t recognize that core name or ID')

  it 'claims core', ->
    promise = client.claimCore('51ff6e065067545724680187')

    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      status = promise.inspect()
      expect(status.state).toBe('rejected')
      expect(status.reason).not.toBe(null)

      expect(status.reason.ok).toBe(false)
      expect(status.reason.errors instanceof Array).toBe(true)
      expect(status.reason.errors.length).toBe(1)
      expect(status.reason.errors[0]).toBe('That belongs to someone else')

  it 'compiles a file', ->
    promise = client.compileCode(['foo.ino'])

    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      status = promise.inspect()
      expect(status.state).toBe('rejected')
      expect(status.reason).not.toBe(null)

      expect(status.reason.ok).toBe(false)
      expect(status.reason.output).toBe('App code was invalid')
      expect(status.reason.stdout).toBe('Nothing to be done for `all\'')
      expect(status.reason.errors instanceof Array).toBe(true)
      expect(status.reason.errors.length).toBe(1)
      expect(status.reason.errors[0]).toBe('make: *** No rule to make target `license.o\'')


describe 'Tests for mocked ApiClient library with devices which should be offline', ->
  client = null
  promise = null

  beforeEach ->
    ApiClient = require './mocks/ApiClient-offline'

    client = new ApiClient apiUrl

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
