whenjs = require 'when'

class ApiClientFail
  constructor: (baseUrl, access_token) ->
    if setTimeout.isSpy
      jasmine.unspy window, 'setTimeout'

  login: (client_id, user, pass) ->
    dfd = whenjs.defer()
    setTimeout ->
      dfd.reject 'Unknown user'
    , 1

    dfd.promise

  listDevices: ->
    dfd = whenjs.defer()
    setTimeout ->
      dfd.resolve {
        "code": 400,
        "error": "invalid_grant",
        "error_description": "The access token provided is invalid."
      }
    , 1
    dfd.promise

  getAttributes: (coreID) ->
    dfd = whenjs.defer()
    setTimeout ->
      dfd.resolve {
        "error": "Permission Denied",
        "info": "I didn't recognize that core name or ID"
      }
    , 1
    dfd.promise

  renameCore: (coreID) ->
    dfd = whenjs.defer()
    setTimeout ->
      dfd.reject {
        "error": "Permission Denied",
        "info": "I didn't recognize that core name or ID"
      }
    , 1
    dfd.promise

  removeCore: (coreID) ->
    dfd = whenjs.defer()
    setTimeout ->
      dfd.reject {
        "error": "Permission Denied",
        "info": "I didn't recognize that core name or ID"
      }
    , 1
    dfd.promise

  claimCore: (coreID) ->
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

  compileCode: (files) ->
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

  downloadBinary: (url, filename) ->
    dfd = whenjs.defer()
    setTimeout ->
      dfd.resolve 'Binary not found'
    , 1
    dfd.promise

  getVariable: (coreID, name) ->
    dfd = whenjs.defer()
    setTimeout ->
      dfd.resolve {
        ok: false,
        error: 'Variable not found'
      }
    , 1
    dfd.promise

module.exports = ApiClientFail
