{WorkspaceView} = require 'atom'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe 'SparkIde', ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide')

  describe 'when the spark-ide:toggle event is triggered', ->
    xit 'attaches and then detaches the view', ->
      expect(atom.workspaceView.find('.spark-ide')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'spark-ide:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.spark-ide')).toExist()
        atom.workspaceView.trigger 'spark-ide:toggle'
        expect(atom.workspaceView.find('.spark-ide')).not.toExist()
