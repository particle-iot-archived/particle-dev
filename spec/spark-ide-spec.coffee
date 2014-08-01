{WorkspaceView} = require 'atom'

describe 'Main Tests', ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide')

  describe 'when the spark-ide:login event is triggered', ->
    it 'shows login view', ->
      expect(atom.workspaceView.find('#spark-ide-login-view')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'spark-ide:login'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('#spark-ide-login-view')).toExist()
