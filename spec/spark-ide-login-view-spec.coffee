{WorkspaceView} = require 'atom'
$ = require('atom').$
settings = null

describe 'Login View Tests', ->
  activationPromise = null
  loginView = null
  originalProfile = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
        loginView = mainModule.loginView

    settings = require '../lib/settings'
    originalProfile = settings.profile
    # For tests not to mess up our profile, we have to switch to test one...
    settings.switchProfile('spark-ide-test')
    # ...but Node.js cache won't allow loading settings.js again so
    # we have to clear it and allow whichProfile() to be called.
    delete require.cache[require.resolve('../lib/settings')]

    atom.workspaceView.trigger 'spark-ide:login'

  afterEach ->
    settings.switchProfile(originalProfile)
    delete require.cache[require.resolve('../lib/settings')]

    atom.workspaceView.trigger 'spark-ide:cancel-login'


  it 'tests hiding and showing', ->
    waitsForPromise ->
      activationPromise

    runs ->
      # beforeEach should show the dialog
      expect(atom.workspaceView.find('#spark-ide-login-view')).toExist()

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
      atom.workspaceView.trigger 'spark-ide:cancel-login'
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
      expect(loginView.spinner.hasClass('hidden')).toBe(true)

      loginView.emailEditor.getEditor().setText 'foo@bar.baz'
      loginView.passwordEditor.originalText = 'foo'
      loginView.login()

      expect(loginView.spinner.hasClass('hidden')).toBe(false)

    waitsFor ->
      !loginView.loginPromise

    runs ->
      context = atom.workspaceView.find('#spark-ide-login-view')
      expect(context.find('.editor.mini:eq(0)').hasClass('editor-error')).toBe(false)
      expect(context.find('.editor.mini:eq(1)').hasClass('editor-error')).toBe(false)
      expect(loginView.spinner.hasClass('hidden')).toBe(true)

      delete require.cache[require.resolve('../lib/settings')]
      settings = require '../lib/settings'

      expect(settings.username).toEqual('foo@bar.baz')
      expect(settings.access_token).toEqual('0123456789abcdef0123456789abcdef')

  it 'tests wrong credentials', ->
    waitsForPromise ->
      activationPromise

    runs ->
      # Mock ApiClient
      require.cache[require.resolve('../lib/ApiClient')].exports = require './mocks/ApiClient-fail'

      context = atom.workspaceView.find('#spark-ide-login-view')
      expect(context.find('.text-error').css 'display').toEqual('none')

      loginView.emailEditor.getEditor().setText 'foo@bar.baz'
      loginView.passwordEditor.originalText = 'foo'
      loginView.login()

    waitsFor ->
      !loginView.loginPromise

    runs ->
      context = atom.workspaceView.find('#spark-ide-login-view')
      expect(context.find('.text-error').css 'display').toEqual('block')
      expect(context.find('.text-error').text()).toEqual('Unknown user')
      expect(loginView.spinner.hasClass('hidden')).toBe(true)

  it 'tests logging out', ->
    waitsForPromise ->
      activationPromise

    runs ->
      settings.username = 'foo@bar.baz'
      settings.override null, 'username', settings.username
      settings.access_token = '0123456789abcdef0123456789abcdef'
      settings.override null, 'access_token', settings.access_token

      atom.workspaceView.trigger 'spark-ide:logout'

      delete require.cache[require.resolve('../lib/settings')]
      settings = require '../lib/settings'

      expect(settings.username).toBe(null)
      expect(settings.access_token).toBe(null)
