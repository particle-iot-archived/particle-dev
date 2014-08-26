{WorkspaceView} = require 'atom'
SettingsHelper = require '../../lib/utils/settings-helper'

describe 'Status Bar Tests', ->
  activationPromise = null
  statusBarPromise = null
  originalProfile = null
  statusView = null

  beforeEach ->
    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-ide-test'

    require '../../lib/vendor/ApiClient'

    atom.workspaceView = new WorkspaceView
    statusBarPromise = atom.packages.activatePackage('status-bar')

    waitsForPromise ->
      statusBarPromise

    runs ->
      activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
        statusView = mainModule.statusView

    waitsForPromise ->
      activationPromise


  afterEach ->
    SettingsHelper.setProfile originalProfile

  describe 'when the spark-ide is activated', ->
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
      statusBar = atom.workspaceView.statusBar.find('#spark-ide-status-bar-view')

      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      require.cache[require.resolve('../../lib/vendor/ApiClient')].exports = require '../mocks/ApiClient-success'

      spyOn statusView, 'getCurrentCoreStatus'
      atom.workspaceView.trigger 'spark-ide:update-core-status'
      expect(statusBar.find('#spark-current-core a').text()).toBe('Foo')
      expect(statusView.getCurrentCoreStatus).toHaveBeenCalled()

      SettingsHelper.clearCurrentCore()
      SettingsHelper.clearCredentials()
      jasmine.unspy statusView, 'getCurrentCoreStatus'


    it 'checks current core status', ->
      # Check async core status checking
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      require.cache[require.resolve('../../lib/vendor/ApiClient')].exports = require '../mocks/ApiClient-success'

      statusView.getCurrentCoreStatus()

      waitsFor ->
        !statusView.getAttributesPromise

      runs ->
        statusBar = atom.workspaceView.statusBar.find('#spark-ide-status-bar-view')
        expect(statusBar.find('#spark-current-core').hasClass('online')).toBe(true)

        require.cache[require.resolve('../../lib/vendor/ApiClient')].exports = require '../mocks/ApiClient-offline'

        statusView.getCurrentCoreStatus()

      waitsFor ->
        !statusView.getAttributesPromise

      runs ->
        statusBar = atom.workspaceView.statusBar.find('#spark-ide-status-bar-view')
        expect(statusBar.find('#spark-current-core').hasClass('online')).toBe(false)

        clearInterval statusView.interval

        SettingsHelper.clearCredentials()
        SettingsHelper.clearCurrentCore()
