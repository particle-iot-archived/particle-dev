{WorkspaceView} = require 'atom'
SettingsHelper = require '../lib/settings-helper'

describe 'Main Tests', ->
  activationPromise = null
  loginView = null
  sparkIde = null
  originalProfile = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
      sparkIde = mainModule
      loginView = mainModule.loginView

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-ide-test'

  afterEach ->
    SettingsHelper.setProfile originalProfile

  describe 'when the spark-ide:login event is triggered', ->
    it 'calls login() method', ->
      waitsForPromise ->
        activationPromise

      runs ->
        spyOn(sparkIde, 'login').andCallThrough()
        atom.workspaceView.trigger 'spark-ide:login'
        expect(sparkIde.login).toHaveBeenCalled()

        atom.workspaceView.trigger 'spark-ide:cancel-login'

  describe 'when the spark-ide:logout event is triggered', ->
    it 'calls logout() method', ->
      waitsForPromise ->
        activationPromise

      runs ->
        spyOn(sparkIde, 'logout').andCallThrough()
        atom.workspaceView.trigger 'spark-ide:logout'
        expect(sparkIde.logout).toHaveBeenCalled()

  describe 'when the spark-ide:select-core event is triggered', ->
    it 'calls selectCore() method', ->
      waitsForPromise ->
        activationPromise

      runs ->
        spyOn(sparkIde, 'selectCore').andCallThrough()
        atom.workspaceView.trigger 'spark-ide:select-core'
        expect(sparkIde.selectCore).toHaveBeenCalled()
