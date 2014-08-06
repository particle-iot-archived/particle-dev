{WorkspaceView} = require 'atom'
settings = null

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
    settings.switchProfile(originalProfile)
    delete require.cache[require.resolve('../lib/settings')]

  describe 'when the spark-ide is activated', ->
    beforeEach ->
      waitsForPromise ->
        activationPromise
      waitsForPromise ->
        statusBarPromise

    it 'attaches custom status bar and updates menu', ->
      statusBar = atom.workspaceView.statusBar.find('#spark-ide-status-bar-view')
      expect(statusBar).toExist()
      expect(statusBar.find('#spark-icon').is(':empty')).toBe(true)
      # User should be logged off
      expect(statusBar.find('#spark-login-status a')).toExist()

      ideMenu = atom.menu.template.filter (value) ->
        value.label == 'Spark IDE'
      expect(ideMenu.length).toBe(1)
      expect(ideMenu[0].submenu[0].label).toBe('Log in to Spark Cloud...')
      expect(ideMenu[0].submenu[0].command).toBe('spark-ide:login')

      expect(statusBar.find('#spark-current-core').hasClass('hidden')).toBe(true)


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

      ideMenu = atom.menu.template.filter (value) ->
        value.label == 'Spark IDE'
      expect(ideMenu.length).toBe(1)
      expect(ideMenu[0].submenu[0].label).toBe('Log out foo@bar.baz')
      expect(ideMenu[0].submenu[0].command).toBe('spark-ide:logout')

      expect(statusBar.find('#spark-current-core').hasClass('hidden')).toBe(false)

      settings.username = null
      settings.access_token = null

    # TODO: Test current core
