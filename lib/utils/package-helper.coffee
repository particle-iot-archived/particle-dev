module.exports = ->
  if @_packageName
    return @_packageName

  try
    pjson = require('../../package.json');
    @_packageName = pjson.name
  catch error
    @_packageName = 'particle-dev'

  @_packageName
