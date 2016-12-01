{DialogView} = require 'particle-dev-views'
packageName = require '../utils/package-helper'

module.exports =
class IdentifyCoreView extends DialogView
  constructor: (coreID) ->
    super
      prompt: 'Your device ID is:'
      initialText: coreID
      select: true
      iconClass: ''
      hideOnBlur: false

    @claimPromise = null
    @prop 'id', 'identify-core-view'
    @addClass packageName()
