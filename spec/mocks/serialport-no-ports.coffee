whenjs = require 'when'
stream = require 'stream'
serialport = require './serialport-success'

module.exports =
  list: (callback) ->
    callback(null, [])

  SerialPort: class extends serialport.SerialPort
