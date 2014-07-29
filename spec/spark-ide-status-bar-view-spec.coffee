{WorkspaceView} = require 'atom'
SparkIde = require '../lib/spark-ide'

describe "SparkIdeStatusBarView", ->
  activationPromise = null
  statusBarPromise = null
  originalProfile = null

  beforeEach ->
    settings = require '../lib/settings'
    originalProfile = settings.profile
    # For tests not to mess up our profile, we have to switch to test one...
    settings.switchProfile('spark-ide-test')
    # ...but Node.js cache won't allow loading settings.js again so
    # we have to clear it and allow whichProfile() to be called.
    delete require.cache[require.resolve('../lib/settings')]

    atom.workspaceView = new WorkspaceView
    statusBarPromise = atom.packages.activatePackage('status-bar')
    activationPromise = atom.packages.activatePackage('spark-ide')

  afterEach ->
    settings = require '../lib/settings'
    settings.switchProfile(originalProfile)
    delete require.cache[require.resolve('../lib/settings')]

  describe "when the spark-ide is activated", ->
    beforeEach ->
      waitsForPromise ->
        activationPromise
      waitsForPromise ->
        statusBarPromise

    it "attaches custom status bar", ->
      statusBar = atom.workspaceView.statusBar.find('#spark-ide-status-bar-view')
      expect(statusBar).toExist()
      expect(statusBar.find('#spark-icon').is(':empty')).toBe(true)
      # User should be logged off
      expect(statusBar.find('#spark-login-status a')).toExist()

    it "checks if username of logged in user is shown", ->
      settings = require '../lib/settings'      
