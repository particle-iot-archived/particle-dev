{WorkspaceView} = require 'atom'
settings = null

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

    settings = require '../lib/settings'
    originalProfile = settings.profile
    # For tests not to mess up our profile, we have to switch to test one...
    settings.switchProfile('spark-ide-test')
    # ...but Node.js cache won't allow loading settings.js again so
    # we have to clear it and allow whichProfile() to be called.
    delete require.cache[require.resolve('../lib/settings')]

  afterEach ->
    settings.switchProfile(originalProfile)
    delete require.cache[require.resolve('../lib/settings')]

  describe 'when the spark-ide:login event is triggered', ->
    it 'shows login view', ->
      waitsForPromise ->
        activationPromise

      runs ->
        spyOn(sparkIde, 'login').andCallThrough()
        atom.workspaceView.trigger 'spark-ide:login'
        expect(sparkIde.login).toHaveBeenCalled()

        atom.workspaceView.trigger 'spark-ide:cancel-login'

  describe 'when the spark-ide:logout event is triggered', ->
    it 'launches logout() method on login view', ->
      waitsForPromise ->
        activationPromise

      runs ->
        spyOn(sparkIde, 'logout').andCallThrough()
        atom.workspaceView.trigger 'spark-ide:logout'
        expect(sparkIde.logout).toHaveBeenCalled()
