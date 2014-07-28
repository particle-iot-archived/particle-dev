ApiClient = require '../../lib/ApiClient'
whenjs = require 'when'

class ApiClientSuccess extends ApiClient
  constructor: (baseUrl, access_token) ->
    super baseUrl, access_token

  login: (client_id, user, pass) ->
    dfd = whenjs.defer()
    this._access_token = '0123456789abcdef0123456789abcdef'
    dfd.resolve(this._access_token)
    dfd.promise

  listDevices: ->
    dfd = whenjs.defer()
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

    dfd.resolve(this._devices)
    dfd.promise


module.exports = ApiClientSuccess
