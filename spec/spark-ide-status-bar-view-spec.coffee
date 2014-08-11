{WorkspaceView} = require 'atom'
SettingsHelper = require '../lib/settings-helper'

describe 'Status Bar Tests', ->
  activationPromise = null
  statusBarPromise = null
  originalProfile = null

  beforeEach ->
    require '../lib/ApiClient'
    
    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-ide-test'

    atom.workspaceView = new WorkspaceView
    statusBarPromise = atom.packages.activatePackage('status-bar')
    activationPromise = atom.packages.activatePackage('spark-ide')

  afterEach ->
    SettingsHelper.setProfile originalProfile
    delete require.cache[require.resolve('../lib/ApiClient')]

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
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      # Refresh UI
      atom.workspaceView.trigger 'spark-ide:update-login-status'

      expect(statusBar.find('#spark-login-status a')).not.toExist()
      expect(statusBar.find('#spark-login-status').text()).toEqual('foo@bar.baz')

      ideMenu = atom.menu.template.filter (value) ->
        value.label == 'Spark IDE'
      expect(ideMenu.length).toBe(1)
      expect(ideMenu[0].submenu[0].label).toBe('Log out foo@bar.baz')
      expect(ideMenu[0].submenu[0].command).toBe('spark-ide:logout')

      expect(statusBar.find('#spark-current-core').hasClass('hidden')).toBe(false)
      expect(statusBar.find('#spark-current-core a').text()).toBe('No cores selected')

      SettingsHelper.clearCredentials()

    it 'checks current core name', ->
      waitsForPromise ->
        activationPromise
      waitsForPromise ->
        statusBarPromise

      runs ->
        statusBar = atom.workspaceView.statusBar.find('#spark-ide-status-bar-view')

        SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
        SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
        require.cache[require.resolve('../lib/ApiClient')].exports = require './mocks/ApiClient-success'

        atom.workspaceView.trigger 'spark-ide:update-core-status'
        expect(statusBar.find('#spark-current-core a').text()).toBe('Foo')

        SettingsHelper.clearCredentials()
        SettingsHelper.clearCurrentCore()

    it 'checks current core status', ->
      waitsForPromise ->
        activationPromise
      waitsForPromise ->
        statusBarPromise

      runs ->
        statusBar = atom.workspaceView.statusBar.find('#spark-ide-status-bar-view')

        SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
        SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
        require.cache[require.resolve('../lib/ApiClient')].exports = require './mocks/ApiClient-success'

        atom.workspaceView.trigger 'spark-ide:update-core-status'

      waitsFor ->
        # Only way to wait for request. This test will timeout instead of failing
        atom.workspaceView.statusBar.find('#spark-ide-status-bar-view').find('#spark-current-core').hasClass('online')

      runs ->
        statusBar = atom.workspaceView.statusBar.find('#spark-ide-status-bar-view')
        require.cache[require.resolve('../lib/ApiClient')].exports = require './mocks/ApiClient-offline'

        atom.workspaceView.trigger 'spark-ide:update-core-status'

      waitsFor ->
        # Only way to wait for request. This test will timeout instead of failing
        !atom.workspaceView.statusBar.find('#spark-ide-status-bar-view').find('#spark-current-core').hasClass('online')

      runs ->
        SettingsHelper.clearCredentials()
        SettingsHelper.clearCurrentCore()
