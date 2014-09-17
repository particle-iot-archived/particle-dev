Spark = require 'spark'
whenjs = require 'when'

module.exports =
  unspyTimers: ->
    if setTimeout.isSpy
      jasmine.unspy window, 'setTimeout'

  stubMethod: (method, stub) ->
    if Spark[method].isSpy
      jasmine.unspy Spark, method
    spyOn(Spark, method).andCallFake stub

  stubSuccess: (method) ->
    @unspyTimers()

    switch method
      when 'login'
        @stubMethod method, (client_id, user, pass) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.resolve {
              access_token: "0123456789abcdef0123456789abcdef",
              token_type: "bearer",
              expires_in: 7776000
            } 
          , 1
          dfd.promise

      when 'listDevices'
        @stubMethod method, ->
          dfd = whenjs.defer()
          setTimeout ->
            this._devices = [
              {
                "id": "51ff6e065067545724680187",
                "name": "Online Core",
                "last_app": null,
                "last_heard": null,
                "requires_deep_update": true,
                "connected": true
              }, {
                "id": "51ff67258067545724380687",
                "name": "Offline Core",
                "last_app": null,
                "last_heard": null,
                "connected": false
              }
            ]
            dfd.resolve this._devices
          , 1
          dfd.promise

      when 'getAttributes'
        @stubMethod method, (coreID) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.resolve {
              "id": coreID,
              "name": "Online Core",
              "connected": true,
              "variables": { foo: 'int32' },
              "functions": [ 'bar' ],
              "cc3000_patch_version": "1.28"
            }
          , 1
          dfd.promise

      when 'renameCore'
        @stubMethod method, (coreID, name) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.resolve {
              "id": coreID,
              "name": name
            }
          , 1
          dfd.promise

      when 'removeCore'
        @stubMethod method, (coreID) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.resolve {
              "ok": true
            }
          , 1
          dfd.promise

      when 'claimCore'
        @stubMethod method, (coreID) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.resolve {
              "ok": true,
              "user_id": "53187f78907210fed300048f",
              "id": coreID,
              "connected": true
            }
          , 1
          dfd.promise

      when 'compileCode'
        @stubMethod method, (files) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.resolve {
              "ok": true,
              "binary_id": "53fdb4b3a7ce5fe43d3cf079"
              "binary_url": "/v1/binaries/53fdb4b3a7ce5fe43d3cf079"
              "expires_at": "2014-08-28T10:36:35.183Z"
              "sizeInfo": "   text	   data	    bss	    dec	    hex	filename\n  74960	   1236	  11876	  88072	  15808	build/foo.elf\n"
            }
          , 1
          dfd.promise

      when 'downloadBinary'
        @stubMethod method, (url, filename) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.resolve 'CONTENTS OF A FILE'
          , 1
          dfd.promise

      when 'getVariable'
        @stubMethod method, (coreID, name) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.resolve {
              cmd: 'VarReturn',
              name: 'foo',
              result: 1,
              coreInfo: {
                last_handshake_at: '2014-09-03T08:59:17.850Z',
                connected: true
              }
            }
          , 1
          dfd.promise

      when 'callFunction'
        @stubMethod method, (coreID, functionName, funcParam) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.resolve {
              id: '51ff6e065067545724680187',
              name: 'Online Core',
              last_app: null,
              connected: true,
              return_value: 200
            }
          , 1
          dfd.promise

  stubFail: (method) ->
    @unspyTimers()

    switch method
      when 'login'
        @stubMethod method, (client_id, user, pass) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.reject 'Unknown user'
          , 1

          dfd.promise

      when 'listDevices'
        @stubMethod method, ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.resolve {
              "code": 400,
              "error": "invalid_grant",
              "error_description": "The access token provided is invalid."
            }
          , 1
          dfd.promise

      when 'getAttributes'
        @stubMethod method, (coreID) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.resolve {
              "error": "Permission Denied",
              "info": "I didn't recognize that core name or ID"
            }
          , 1
          dfd.promise

      when 'renameCore'
        @stubMethod method, (coreID) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.reject {
              "error": "Permission Denied",
              "info": "I didn't recognize that core name or ID"
            }
          , 1
          dfd.promise

      when 'removeCore'
        @stubMethod method, (coreID) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.reject {
              "error": "Permission Denied",
              "info": "I didn't recognize that core name or ID"
            }
          , 1
          dfd.promise

      when 'claimCore'
        @stubMethod method, (coreID) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.reject {
              "ok": false,
              "errors": [
                "That belongs to someone else"
              ]
            }
          , 1
          dfd.promise

      when 'compileCode'
        @stubMethod method, (files) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.resolve {
              "ok": false,
              "errors": [
                "Blink.cpp: In function 'void setup()':\n\
      Blink.cpp:11:17: error: 'OUTPUTz' was not declared in this scope\n\
       void setup() {\n\
                       ^\n\
      make: *** [Blink.o] Error 1"
              ],
              "output": "App code was invalid",
              "stdout": "Nothing to be done for `all'"
            }
          , 1
          dfd.promise

      when 'downloadBinary'
        @stubMethod method, (url, filename) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.resolve 'Binary not found'
          , 1
          dfd.promise

      when 'getVariable'
        @stubMethod method, (coreID, name) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.resolve {
              ok: false,
              error: 'Variable not found'
            }
          , 1
          dfd.promise

      when 'callFunction'
        @stubMethod method, (coreID, functionName, funcParam) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.resolve {
              ok: false,
              error: 'Function not found'
            }
          , 1
          dfd.promise

  stubOffline: (method) ->
    @unspyTimers()

    switch method
      when 'listDevices'
        @stubMethod method, ->
          dfd = whenjs.defer()
          setTimeout ->
            this._devices = [
              {
                "id": "51ff6e065067545724680187",
                "name": "Online Core",
                "last_app": null,
                "last_heard": null,
                "requires_deep_update": true,
                "connected": false
              }, {
                "id": "51ff67258067545724380687",
                "name": "Offline Core",
                "last_app": null,
                "last_heard": null,
                "connected": false
              }
            ]
            dfd.resolve this._devices
          , 1
          dfd.promise

      when 'getAttributes'
        @stubMethod method, (coreID) ->
          dfd = whenjs.defer()
          setTimeout ->
            dfd.resolve {
              "id": coreID,
              "name": "Online Core",
              "connected": false,
              "variables": {},
              "functions": [],
              "cc3000_patch_version": "1.28"
            }
          , 1
          dfd.promise
