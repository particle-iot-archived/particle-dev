{WorkspaceView} = require 'atom'
$ = require('atom').$

describe 'Login View Tests', ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide')
    atom.workspaceView.trigger 'spark-ide:login'

  afterEach ->
    atom.workspaceView.trigger 'spark-ide:cancelLogin'

  it 'checks validation', ->
    waitsForPromise ->
      activationPromise

    runs ->
      # Test core:cancel
      expect(atom.workspaceView.find('#spark-ide-login-view')).toExist()
      atom.workspaceView.trigger 'core:cancel'
      expect(atom.workspaceView.find('#spark-ide-login-view')).not.toExist()
      atom.workspaceView.trigger 'spark-ide:login'
      expect(atom.workspaceView.find('#spark-ide-login-view')).toExist()
      # Test core:close
      atom.workspaceView.trigger 'core:close'
      expect(atom.workspaceView.find('#spark-ide-login-view')).not.toExist()
      atom.workspaceView.trigger 'spark-ide:login'
      expect(atom.workspaceView.find('#spark-ide-login-view')).toExist()
      # Test spark-ide:cancelLogin
      atom.workspaceView.trigger 'spark-ide:cancelLogin'
      expect(atom.workspaceView.find('#spark-ide-login-view')).not.toExist()
      atom.workspaceView.trigger 'spark-ide:login'

      # Test empty fields
      context = atom.workspaceView.find('#spark-ide-login-view')
      expect(context.find('.editor.mini:eq(0)').hasClass('editor-error')).toBe(false)
      expect(context.find('.editor.mini:eq(1)').hasClass('editor-error')).toBe(false)
      atom.workspaceView.find('#spark-ide-login-view #loginButton').click()
      expect(context.find('.editor.mini:eq(0)').hasClass('editor-error')).toBe(true)
      expect(context.find('.editor.mini:eq(1)').hasClass('editor-error')).toBe(true)

      # Restart
      atom.workspaceView.trigger 'spark-ide:cancelLogin'
      atom.workspaceView.trigger 'spark-ide:login'

      # Test invalid input
      expect(context.find('.editor.mini:eq(0)').hasClass('editor-error')).toBe(false)
      expect(context.find('.editor.mini:eq(1)').hasClass('editor-error')).toBe(false)

      context.find('.editor.mini:eq(0) .hidden-input').val 'qwertyuiop'

      # Fake space key
      passwordInput = context.find('.editor.mini:eq(1) .hidden-input')
      e = $.Event 'keypress'
      e.which = 32
      passwordInput.trigger e

      context.find('#loginButton').click()

      expect(context.find('.editor.mini:eq(0)').hasClass('editor-error')).toBe(true)
      expect(context.find('.editor.mini:eq(1)').hasClass('editor-error')).toBe(true)
