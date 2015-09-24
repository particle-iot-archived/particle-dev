{DialogView} = require 'particle-dev-views'
SettingsHelper = null
_s = null

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
    @prop 'id', 'spark-dev-identify-core-view'
