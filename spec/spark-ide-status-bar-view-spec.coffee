{WorkspaceView} = require 'atom'

describe 'Status Bar Tests', ->
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
    settings.username = null
    settings.access_token = null

    settings.switchProfile(originalProfile)
    delete require.cache[require.resolve('../lib/settings')]

  describe 'when the spark-ide is activated', ->
    beforeEach ->
      waitsForPromise ->
        activationPromise
      waitsForPromise ->
        statusBarPromise

    it 'attaches custom status bar', ->
      statusBar = atom.workspaceView.statusBar.find('#spark-ide-status-bar-view')
      expect(statusBar).toExist()
      expect(statusBar.find('#spark-icon').is(':empty')).toBe(true)
      # User should be logged off
      expect(statusBar.find('#spark-login-status a')).toExist()

    it 'checks if username of logged in user is shown', ->
      statusBar = atom.workspaceView.statusBar.find('#spark-ide-status-bar-view')
      # Previously logged out user
      expect(statusBar.find('#spark-login-status a')).toExist()
      # Log user in
      settings = require '../lib/settings'
      settings.username = 'foo@bar.baz'
      settings.access_token = '0123456789abcdef0123456789abcdef'

      # Refresh UI
      atom.workspaceView.trigger 'spark-ide:updateLoginStatus'

      expect(statusBar.find('#spark-login-status a')).not.toExist()
      expect(statusBar.find('#spark-login-status').text()).toEqual('foo@bar.baz')
