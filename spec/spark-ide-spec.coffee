{WorkspaceView} = require 'atom'
SettingsHelper = require '../lib/utils/settings-helper'

describe 'Main Tests', ->
  activationPromise = null
  treeViewPromise = null
  loginView = null
  sparkIde = null
  originalProfile = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
      sparkIde = mainModule
      loginView = mainModule.loginView
    treeViewPromise = atom.packages.activatePackage('tree-view')

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


  describe 'when the spark-ide:rename-core event is triggered', ->
    it 'calls renameCore() method', ->
      waitsForPromise ->
        activationPromise

      waitsForPromise ->
        treeViewPromise

      runs ->
        spyOn(sparkIde, 'renameCore').andCallThrough()
        atom.workspaceView.trigger 'spark-ide:rename-core'
        expect(sparkIde.renameCore).toHaveBeenCalled()
