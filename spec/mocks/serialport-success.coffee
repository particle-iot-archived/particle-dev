whenjs = require 'when'
stream = require 'stream'

module.exports =
  list: (callback) ->
    console.log 'Success'
    callback(null, [{
      comName: "/dev/cu.usbmodemfa1234"
      locationId: "0xfa532000"
      manufacturer: "Spark Devices     "
      pnpId: ""
      productId: "0x607d"
      serialNumber: "8D7028785754"
      vendorId: "0x1d50"
    }])

  SerialPort: class extends stream.Stream
    constructor: (path, options, openImmediately, callback) ->
      if setTimeout.isSpy
        jasmine.unspy window, 'setTimeout'
      if clearTimeout.isSpy
        jasmine.unspy window, 'clearTimeout'

      @parser = options.parser
      @lastResponse = 0

    respond: (nextResponse)->
      setTimeout =>
        switch nextResponse
          when 1
            @parser(this, 'Your core id is 0123456789abcdef0123456789abcdef')
          when 2
            @parser(this, 'SSID:')
          when 3
            @parser(this, 'Security 0=unsecured, 1=WEP, 2=WPA, 3=WPA2:')
          when 4
            @parser(this, 'Password:')
          when 5
            @parser(this, 'Spark <3 you!')

        @lastResponse = nextResponse
      , 100

    open: (callback) ->
      if !!callback
        callback()

    write: (buffer, callback) ->
      if buffer == 'i'
        @respond(1)
      else if buffer == 'w'
        @respond(2)
      else @respond(@lastResponse + 1)

      if !!callback
        callback()

    close: (callback) ->
      @lastResponse = 0
      if !!callback
        callback()

    drain: (callback) ->
      if !!callback
        callback()

    flush: (callback) ->
      if !!callback
        callback()
