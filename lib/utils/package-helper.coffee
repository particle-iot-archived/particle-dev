module.exports = ->
  if @_packageName
    return @_packageName

  pjson = require('../../package.json');
  @_packageName = pjson.name
