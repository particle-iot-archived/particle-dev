Dialog = require(atom.packages.getLoadedPackage('tree-view')?.path + '/lib/dialog')

module.exports =
class RenameCoreView extends Dialog
  constructor: (@initialName) ->
    super
      prompt: 'Enter new name for this Core'
      initialPath: @initialName
      select: true
      iconClass: ''

  onConfirm: (newName) ->
    @close()
