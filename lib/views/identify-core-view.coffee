{Dialog} = require 'spark-dev-views'
SettingsHelper = null
_s = null

module.exports =
class IdentifyCoreView extends Dialog
  constructor: (coreID) ->
    super
      prompt: 'Your device ID is:'
      initialText: coreID
      select: true
      iconClass: ''
      hideOnBlur: false

    @claimPromise = null
    @prop 'id', 'spark-dev-identify-core-view'
