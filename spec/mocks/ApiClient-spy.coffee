whenjs = require 'when'

class ApiClientSpy
  constructor: (baseUrl, access_token) ->
    if setTimeout.isSpy
      jasmine.unspy window, 'setTimeout'

    @compileCode = jasmine.createSpy('compileCode')
    @compileCode.plan = ->
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
      return dfd.promise
    @compileCode.baseObj = @
    @compileCode.methodName = 'compileCode'
    @compileCode.originalValue = ->
    jasmine.getEnv().currentSpec.spies_.push @compileCode

    @downloadBinary = jasmine.createSpy('downloadBinary')
    @downloadBinary.plan = ->
      dfd = whenjs.defer()
      setTimeout ->
        dfd.resolve 'CONTENTS OF A FILE'
      , 1
      return dfd.promise
    @downloadBinary.baseObj = @
    @downloadBinary.methodName = 'downloadBinary'
    @downloadBinary.originalValue = ->
    jasmine.getEnv().currentSpec.spies_.push @downloadBinary

module.exports = ApiClientSpy
