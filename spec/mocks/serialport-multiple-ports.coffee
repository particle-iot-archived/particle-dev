whenjs = require 'when'
stream = require 'stream'
serialport = require './serialport-success'

module.exports =
  list: (callback) ->
    callback(null, [{
      comName: "/dev/cu.usbmodemfa1234"
      locationId: "0xfa532000"
      manufacturer: "Spark Devices     "
      pnpId: ""
      productId: "0x607d"
      serialNumber: "8D7028785754"
      vendorId: "0x1d50"
    },{
      comName: "/dev/cu.usbmodemfab1234"
      locationId: "0xfa532000"
      manufacturer: "Spark Devices     "
      pnpId: ""
      productId: "0x607d"
      serialNumber: "8D7028785755"
      vendorId: "0x1d50"
    }])

  SerialPort: class extends serialport.SerialPort
