whenjs = require 'when'

class ApiClientSuccess
  constructor: (baseUrl, access_token) ->
    if setTimeout.isSpy
      jasmine.unspy window, 'setTimeout'

    @compileCode = jasmine.createSpy('compileCode')
    @compileCode.plan = ->
      return whenjs.defer().promise

    # jasmine.getEnv().currentSpec.spies_.push @compileCode

    @downloadBinary = jasmine.createSpy('downloadBinary')
    @downloadBinary.plan = ->
      return whenjs.defer().promise

    # jasmine.getEnv().currentSpec.spies_.push @downloadBinary

module.exports = ApiClientSuccess
