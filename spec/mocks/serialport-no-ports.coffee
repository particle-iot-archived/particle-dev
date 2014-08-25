whenjs = require 'when'
stream = require 'stream'
serialport = require './serialport-success'

module.exports = serialport
module.exports.list = (callback) ->
  callback(null, [])
