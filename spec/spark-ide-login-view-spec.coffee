{WorkspaceView} = require 'atom'
$ = require('atom').$

describe 'Login View Tests', ->
  activationPromise = null
  loginView = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
        loginView = mainModule.loginView

    atom.workspaceView.trigger 'spark-ide:login'

  afterEach ->
    atom.workspaceView.trigger 'spark-ide:cancelLogin'

  it 'tests hiding and showing', ->
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


  it 'tests empty values', ->
    waitsForPromise ->
      activationPromise

    runs ->
      context = atom.workspaceView.find('#spark-ide-login-view')
      expect(context.find('.editor.mini:eq(0)').hasClass('editor-error')).toBe(false)
      expect(context.find('.editor.mini:eq(1)').hasClass('editor-error')).toBe(false)

      loginView.login()

      expect(context.find('.editor.mini:eq(0)').hasClass('editor-error')).toBe(true)
      expect(context.find('.editor.mini:eq(1)').hasClass('editor-error')).toBe(true)


  it 'tests invalid values', ->
    waitsForPromise ->
      activationPromise

    runs ->
      context = atom.workspaceView.find('#spark-ide-login-view')
      expect(context.find('.editor.mini:eq(0)').hasClass('editor-error')).toBe(false)
      expect(context.find('.editor.mini:eq(1)').hasClass('editor-error')).toBe(false)

      loginView.emailEditor.getEditor().setText 'foobarbaz'
      loginView.passwordEditor.originalText = ' '
      loginView.login()

      expect(context.find('.editor.mini:eq(0)').hasClass('editor-error')).toBe(true)
      expect(context.find('.editor.mini:eq(1)').hasClass('editor-error')).toBe(true)


  it 'tests valid values', ->
    waitsForPromise ->
      activationPromise

    runs ->
      # Mock ApiClient
      require.cache[require.resolve('../lib/ApiClient')].exports = require './mocks/ApiClient-success'

      context = atom.workspaceView.find('#spark-ide-login-view')
      expect(context.find('.editor.mini:eq(0)').hasClass('editor-error')).toBe(false)
      expect(context.find('.editor.mini:eq(1)').hasClass('editor-error')).toBe(false)

      loginView.emailEditor.getEditor().setText 'foo@bar.baz'
      loginView.passwordEditor.originalText = 'foo'
      loginView.login()

      expect(context.find('.editor.mini:eq(0)').hasClass('editor-error')).toBe(false)
      expect(context.find('.editor.mini:eq(1)').hasClass('editor-error')).toBe(false)
