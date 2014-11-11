{WorkspaceView} = require 'atom'
$ = require('atom').$
SettingsHelper = require '../../lib/utils/settings-helper'
SparkStub = require '../stubs/spark'

describe 'Login View', ->
  activationPromise = null
  sparkIde = null
  loginView = null
  originalProfile = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-dev').then ({mainModule}) ->
      sparkIde = mainModule
      sparkIde.initView 'login'
      loginView = sparkIde.loginView

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-dev-test'

    waitsForPromise ->
      activationPromise

  afterEach ->
    SettingsHelper.setProfile originalProfile

    atom.workspaceView.trigger 'spark-dev:cancel-login'

  describe 'when Login View is activated', ->
    beforeEach ->
      atom.workspaceView.trigger 'spark-dev:login'

    it 'tests hiding and showing', ->
      # beforeEach should show the dialog
      expect(atom.workspaceView.find('#spark-dev-login-view')).toExist()

      # Test core:cancel
      expect(atom.workspaceView.find('#spark-dev-login-view')).toExist()
      atom.workspaceView.trigger 'core:cancel'
      expect(atom.workspaceView.find('#spark-dev-login-view')).not.toExist()
      atom.workspaceView.trigger 'spark-dev:login'
      expect(atom.workspaceView.find('#spark-dev-login-view')).toExist()

      # Test core:close
      atom.workspaceView.trigger 'core:close'
      expect(atom.workspaceView.find('#spark-dev-login-view')).not.toExist()
      atom.workspaceView.trigger 'spark-dev:login'
      expect(atom.workspaceView.find('#spark-dev-login-view')).toExist()

      # Test spark-dev:cancelLogin
      atom.workspaceView.trigger 'spark-dev:cancel-login'
      expect(atom.workspaceView.find('#spark-dev-login-view')).not.toExist()


    it 'tests empty values', ->
      context = atom.workspaceView.find('#spark-dev-login-view')
      expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(false)
      expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(false)

      loginView.login()

      expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(true)
      expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(true)


    it 'tests invalid values', ->
      context = atom.workspaceView.find('#spark-dev-login-view')
      expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(false)
      expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(false)

      loginView.emailEditor.getEditor().setText 'foobarbaz'
      loginView.passwordEditor.originalText = ' '
      loginView.login()

      expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(true)
      expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(true)


    it 'tests valid values', ->
      SparkStub.stubSuccess 'login'

      context = atom.workspaceView.find('#spark-dev-login-view')
      expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(false)
      expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(false)
      expect(loginView.spinner.hasClass('hidden')).toBe(true)

      loginView.emailEditor.getEditor().setText 'foo@bar.baz'
      loginView.passwordEditor.originalText = 'foo'
      loginView.login()

      expect(loginView.spinner.hasClass('hidden')).toBe(false)

      waitsFor ->
        !loginView.loginPromise

      runs ->
        context = atom.workspaceView.find('#spark-dev-login-view')
        expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(false)
        expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(false)
        expect(loginView.spinner.hasClass('hidden')).toBe(true)

        expect(SettingsHelper.get('username')).toEqual('foo@bar.baz')
        expect(SettingsHelper.get('access_token')).toEqual('0123456789abcdef0123456789abcdef')

        SettingsHelper.clearCredentials()


    it 'tests wrong credentials', ->
      SparkStub.stubFail 'login'

      context = atom.workspaceView.find('#spark-dev-login-view')
      expect(context.find('.text-error').css 'display').toEqual('none')

      loginView.emailEditor.getEditor().setText 'foo@bar.baz'
      loginView.passwordEditor.originalText = 'foo'
      loginView.login()

      waitsFor ->
        !loginView.loginPromise

      runs ->
        context = atom.workspaceView.find('#spark-dev-login-view')
        expect(context.find('.text-error').css 'display').toEqual('block')
        expect(context.find('.text-error').text()).toEqual('Unknown user')
        expect(loginView.spinner.hasClass('hidden')).toBe(true)


    it 'tests logging out', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      atom.workspaceView.trigger 'spark-dev:logout'

      expect(SettingsHelper.get('username')).toEqual(null)
      expect(SettingsHelper.get('access_token')).toEqual(null)
