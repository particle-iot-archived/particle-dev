{WorkspaceView} = require 'atom'

describe 'Main Tests', ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide')

  describe 'when the spark-ide:login event is triggered', ->
    it 'shows login view', ->
      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('#spark-ide-login-view')).not.toExist()
        atom.workspaceView.trigger 'spark-ide:login'
        expect(atom.workspaceView.find('#spark-ide-login-view')).toExist()
        atom.workspaceView.trigger 'spark-ide:cancelLogin'
        expect(atom.workspaceView.find('#spark-ide-login-view')).not.toExist()
