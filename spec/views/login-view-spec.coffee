{$} = require 'atom-space-pen-views'
SettingsHelper = require '../../lib/utils/settings-helper'
SparkStub = require('particle-dev-spec-stubs').spark
spark = require 'spark'

describe 'Login View', ->
  activationPromise = null
  sparkIde = null
  loginView = null
  originalProfile = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

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

  describe 'when Login View is activated', ->
    beforeEach ->
      spyOn atom.commands, 'dispatch'
      loginView.show()

    afterEach ->
      loginView.hide()
      jasmine.unspy atom.commands, 'dispatch'

    it 'tests empty values', ->
      context = $(loginView.element)
      expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(false)
      expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(false)

      loginView.login()

      expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(true)
      expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(true)
      expect(atom.commands.dispatch).not.toHaveBeenCalled()


    it 'tests invalid values', ->
      context = $(loginView.element)
      expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(false)
      expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(false)

      loginView.emailEditor.editor.getModel().setText 'foobarbaz'
      loginView.passwordEditor.editor.getModel().setText ' '
      loginView.login()

      expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(true)
      expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(true)
      expect(atom.commands.dispatch).not.toHaveBeenCalled()


    it 'tests valid values', ->
      SparkStub.stubSuccess spark, 'login'

      context = $(loginView.element)
      expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(false)
      expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(false)
      expect(loginView.spinner.hasClass('hidden')).toBe(true)

      loginView.emailEditor.editor.getModel().setText 'foo@bar.baz'
      loginView.passwordEditor.editor.getModel().setText 'foo'
      loginView.login()

      expect(loginView.spinner.hasClass('hidden')).toBe(false)

      waitsFor ->
        !loginView.loginPromise

      runs ->
        expect(context.find('.editor:eq(0)').hasClass('editor-error')).toBe(false)
        expect(context.find('.editor:eq(1)').hasClass('editor-error')).toBe(false)
        expect(loginView.spinner.hasClass('hidden')).toBe(true)
        expect(atom.commands.dispatch).toHaveBeenCalled()

        expect(SettingsHelper.get('username')).toEqual('foo@bar.baz')
        expect(SettingsHelper.get('access_token')).toEqual('0123456789abcdef0123456789abcdef')

        SettingsHelper.clearCredentials()


    it 'tests wrong credentials', ->
      SparkStub.stubFail spark, 'login'

      context = $(loginView.element)
      expect(context.find('.text-error').css 'display').toEqual('none')

      loginView.emailEditor.editor.getModel().setText 'foo@bar.baz'
      loginView.passwordEditor.editor.getModel().setText 'foo'
      loginView.login()

      waitsFor ->
        !loginView.loginPromise

      runs ->
        context = $(loginView.element)
        expect(context.find('.text-error').css 'display').toEqual('block')
        expect(context.find('.text-error').text()).toEqual('Invalid email or password')
        expect(loginView.spinner.hasClass('hidden')).toBe(true)


    it 'tests logging out', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      loginView.logout()

      expect(SettingsHelper.get('username')).toEqual(null)
      expect(SettingsHelper.get('access_token')).toEqual(null)
