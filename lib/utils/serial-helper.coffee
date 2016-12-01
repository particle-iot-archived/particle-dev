whenjs = require 'when'
pipeline = require 'when/pipeline'
serialport = null
utilities = require '../vendor/utilities.js'
SerialBoredParser = require '../vendor/SerialBoredParser'

# CoffeeScript port of SerialCommand.js functions from spark-cli

module.exports =
  listPorts: ->
    # Return promise with core's serial ports
    serialport = require 'serialport'
    dfd = whenjs.defer()

    cores = []
    serialport.list (err, ports) ->
      if ports
        for port in ports
          if (port.manufacturer && port.manufacturer.indexOf("Spark") >= 0) ||
              (port.pnpId && port.pnpId.indexOf("Spark_Core") >= 0)
            cores.push port

      if !cores.length
        for port in ports
          if port.comName.indexOf('/dev/ttyACM') == 0
            cores.push port
          else if port.comName.indexOf('/dev/cuaU') == 0
            cores.push port

      dfd.resolve(cores)
    dfd.promise

  askForCoreID: (comPort) ->
    # Return promise with core's ID
    serialport = require 'serialport'
    failDelay = 5000
    dfd = whenjs.defer()

    try
      boredDelay = 100
      boredTimer = []
      chunks = []

      serialPort = new serialport.SerialPort comPort, {
        baudrate: 9600,
        parser: SerialBoredParser.MakeParser 250
      }, false

      whenBored = ->
        data = chunks.join ''
        prefix = 'Your core id is '
        if data.indexOf(prefix) >= 0
          data = data.replace(prefix, '').trim()
          dfd.resolve data

      failTimer = setTimeout ->
        dfd.reject 'Serial timed out'
      , failDelay

      serialPort.on 'data', (data) ->
        clearTimeout failTimer
        clearTimeout boredTimer

        chunks.push data
        boredTimer = setTimeout whenBored, boredDelay

      serialPort.open (err) ->
        if err
          dfd.reject 'Serial problems, please reconnect the core.'
        else
          serialPort.write 'i'

      whenjs(dfd.promise).ensure ->
        serialPort.removeAllListeners 'open'
        serialPort.removeAllListeners 'data'

    catch
      dfd.reject 'Serial errors'

    whenjs(dfd.promise).ensure ->
      serialPort.close()

  serialPromptDfd: (serialPort, prompt, answer, timeout, alwaysResolve) ->
    # Return promise of serial prompt and answer
    serialport = require 'serialport'
    dfd = whenjs.defer()
    failTimer = true
    showTraffic = true

    writeAndDrain = (data, callback) ->
      serialPort.write data, ->
        serialPort.drain callback

    if timeout
      failTimer = setTimeout ->
        if showTraffic
          console.log 'Timed out on ' + prompt
        if alwaysResolve
          dfd.resolve null
        else
          dfd.reject 'Serial prompt timed out - Please try restarting your core'
      , timeout

    if prompt
      onMessage = (data) ->
        data = data.toString()

        if showTraffic
          console.log 'Serial said: ' + data
        if data && data.indexOf(prompt) >= 0
          if answer
            serialPort.flush ->

            writeAndDrain answer, ->
              if showTraffic
                console.log 'I said: ' + answer
              dfd.resolve true
          else
            dfd.resolve true

      serialPort.on 'data', onMessage

      whenjs(dfd.promise).ensure ->
        clearTimeout failTimer
        serialPort.removeListener 'data', onMessage
    else if answer
      clearTimeout failTimer

      if showTraffic
        console.log 'I said: ' + answer

      writeAndDrain answer, ->
        dfd.resolve true

    dfd.promise

  serialWifiConfig: (comPort, ssid, password, securityType, failDelay) ->
    # Return prmise of setting WiFi credentials
    serialport = require 'serialport'
    dfd = whenjs.defer()

    serialPort = new serialport.SerialPort comPort, {
      baudrate: 9600,
      parser: SerialBoredParser.MakeParser 250
    }, false

    serialPort.on 'error', ->
      dfd.reject 'Serial error'

    serialPort.open =>
      configDone = pipeline [
        =>
          @serialPromptDfd serialPort, null, 'w', 5000, true
        , (result) =>
          if !result
            return @serialPromptDfd serialPort, null, 'w', 5000, true
          else
            return whenjs.resolve()
        , =>
          @serialPromptDfd serialPort, "SSID:", ssid + "\n", 5000, false
        , =>
          prompt = "Security 0=unsecured, 1=WEP, 2=WPA, 3=WPA2:"
          @serialPromptDfd serialPort, prompt, securityType + "\n", 1500, true
        , (result) =>
          passPrompt = "Password:"
          if !result
            passPrompt = null

          if !passPrompt || !password || (password == "")
            return whenjs.resolve()

          return @serialPromptDfd serialPort, passPrompt, password + "\n", 5000
        , =>
          return @serialPromptDfd serialPort, "Spark <3 you!", null, 15000
      ]
      utilities.pipeDeferred configDone, dfd

      whenjs(dfd.promise).ensure ->
        serialPort.close()

    dfd.promise
