{WorkspaceView} = require 'atom'

describe 'Login View Tests', ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide')
    atom.workspaceView.trigger 'spark-ide:login'

  describe 'when `core:cancel` or `core:close` command is triggered', ->
    it 'hides login view', ->
      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('#spark-ide-login-view')).toExist()
        atom.workspaceView.trigger 'core:cancel'
        expect(atom.workspaceView.find('#spark-ide-login-view')).not.toExist()
        atom.workspaceView.trigger 'spark-ide:login'
        expect(atom.workspaceView.find('#spark-ide-login-view')).toExist()
        atom.workspaceView.trigger 'core:close'
        expect(atom.workspaceView.find('#spark-ide-login-view')).not.toExist()
