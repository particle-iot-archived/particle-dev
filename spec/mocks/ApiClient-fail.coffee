ApiClient = require '../../lib/vendor/ApiClient'
whenjs = require 'when'

class ApiClientFail extends ApiClient
  constructor: (baseUrl, access_token) ->
    super baseUrl, access_token

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


module.exports = ApiClientFail
