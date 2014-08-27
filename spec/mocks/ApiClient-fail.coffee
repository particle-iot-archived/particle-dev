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
      dfd.reject {
        "ok": false,
        "errors": [
          "make: *** No rule to make target `license.o'"
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

module.exports = ApiClientFail
