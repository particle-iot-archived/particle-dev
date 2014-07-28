ApiClient = require '../../lib/ApiClient'
whenjs = require 'when'

class ApiClientMock extends ApiClient
  constructor: (baseUrl, access_token) ->
    super baseUrl, access_token

  login: (client_id, user, pass) ->
    dfd = whenjs.defer()
    this._access_token = '0123456789abcdef0123456789abcdef'
    dfd.resolve(this._access_token)
    dfd.promise


module.exports = ApiClientMock
