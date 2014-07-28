ApiClient = require '../../lib/ApiClient'
whenjs = require 'when'

class ApiClientFail extends ApiClient
  constructor: (baseUrl, access_token) ->
    super baseUrl, access_token

  login: (client_id, user, pass) ->
    dfd = whenjs.defer()
    dfd.reject('Unknown user')
    dfd.promise

  listDevices: ->
    dfd = whenjs.defer()
    dfd.resolve({
      "code": 400,
      "error": "invalid_grant",
      "error_description": "The access token provided is invalid."
    })
    dfd.promise


module.exports = ApiClientFail
