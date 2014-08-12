{WorkspaceView} = require 'atom'
SettingsHelper = require '../lib/utils/settings-helper'

describe 'Status Bar Tests', ->
  activationPromise = null
  statusBarPromise = null
  originalProfile = null

  beforeEach ->
    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-ide-test'

    atom.workspaceView = new WorkspaceView
    statusBarPromise = atom.packages.activatePackage('status-bar')
    activationPromise = atom.packages.activatePackage('spark-ide')

  afterEach ->
    SettingsHelper.setProfile originalProfile

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
        require.cache[require.resolve('../lib/vendor/ApiClient')].exports = require './mocks/ApiClient-success'

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
        require.cache[require.resolve('../lib/vendor/ApiClient')].exports = require './mocks/ApiClient-success'

        atom.workspaceView.trigger 'spark-ide:update-core-status'

      waitsFor ->
        # Only way to wait for request. This test will timeout instead of failing
        atom.workspaceView.statusBar.find('#spark-ide-status-bar-view').find('#spark-current-core').hasClass('online')

      runs ->
        statusBar = atom.workspaceView.statusBar.find('#spark-ide-status-bar-view')
        require.cache[require.resolve('../lib/vendor/ApiClient')].exports = require './mocks/ApiClient-offline'

        atom.workspaceView.trigger 'spark-ide:update-core-status'

      waitsFor ->
        # Only way to wait for request. This test will timeout instead of failing
        !atom.workspaceView.statusBar.find('#spark-ide-status-bar-view').find('#spark-current-core').hasClass('online')

      runs ->
        SettingsHelper.clearCredentials()
        SettingsHelper.clearCurrentCore()
