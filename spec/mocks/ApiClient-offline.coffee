ApiClient = require '../../lib/ApiClient'
whenjs = require 'when'
request = require 'request'

class ApiClientOffline extends ApiClient
  constructor: (baseUrl, access_token) ->
    super baseUrl, access_token

  listDevices: ->
    dfd = whenjs.defer()
    request {
        uri: 'http://httpbin.org/'
    }, (error, response, body) ->
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
    dfd.promise

  getAttributes: (coreID) ->
    dfd = whenjs.defer()
    request {
        uri: 'http://httpbin.org/'
    }, (error, response, body) ->
      dfd.resolve {
        "id": "51ff6e065067545724680187",
        "name": "Online Core",
        "connected": false,
        "variables": {},
        "functions": [],
        "cc3000_patch_version": "1.28"
      }
    dfd.promise


module.exports = ApiClientOffline
