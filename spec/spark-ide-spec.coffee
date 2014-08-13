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

    waitsForPromise ->
      activationPromise

  afterEach ->
    SettingsHelper.setProfile originalProfile


  describe 'when the spark-ide:login event is triggered', ->
    it 'calls login() method', ->
      spyOn(sparkIde, 'login')
      atom.workspaceView.trigger 'spark-ide:login'
      expect(sparkIde.login).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'login'


  describe 'when the spark-ide:logout event is triggered', ->
    it 'calls logout() method', ->
      spyOn(sparkIde, 'logout')
      atom.workspaceView.trigger 'spark-ide:logout'
      expect(sparkIde.logout).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'logout'


  describe 'when the spark-ide:select-core event is triggered', ->
    it 'calls selectCore() method', ->
      spyOn(sparkIde, 'selectCore')
      atom.workspaceView.trigger 'spark-ide:select-core'
      expect(sparkIde.selectCore).toHaveBeenCalled()
      jasmine.unspy sparkIde, 'selectCore'


  describe 'when the spark-ide:rename-core event is triggered', ->
    it 'calls renameCore() method', ->
      waitsForPromise ->
        treeViewPromise

      runs ->
        spyOn(sparkIde, 'renameCore')
        atom.workspaceView.trigger 'spark-ide:rename-core'
        expect(sparkIde.renameCore).toHaveBeenCalled()
        jasmine.unspy sparkIde, 'renameCore'
