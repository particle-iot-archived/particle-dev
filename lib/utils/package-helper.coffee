module.exports = ->
  if @_packageName
    return @_packageName

  try
    pjson = require '../../package.json'
    @_packageName = pjson.name
  catch
    @_packageName = 'particle-dev'

  @_packageName
