{WorkspaceView} = require 'atom'
SettingsHelper = require '../../lib/utils/settings-helper'
SparkStub = require('spark-dev-spec-stubs').spark
spark = require 'spark'

describe 'Status Bar Tests', ->
  activationPromise = null
  statusBarPromise = null
  originalProfile = null
  sparkIde = null
  statusView = null

  beforeEach ->
    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-dev-test'

    SparkStub.stubSuccess spark, 'getAttributes'

    atom.workspaceView = new WorkspaceView
    statusBarPromise = atom.packages.activatePackage('status-bar')

    waitsForPromise ->
      statusBarPromise

    runs ->
      activationPromise = atom.packages.activatePackage('spark-dev').then ({mainModule}) ->
        sparkIde = mainModule
        statusView = sparkIde.statusView

    waitsForPromise ->
      activationPromise


  afterEach ->
    SettingsHelper.setProfile originalProfile

  describe 'when the spark-dev is activated', ->
    it 'attaches custom status bar', ->
      statusBar = atom.workspaceView.statusBar.find('#spark-dev-status-bar-view')
      expect(statusBar).toExist()
      expect(statusBar.find('#spark-icon').is(':empty')).toBe(true)
      # User should be logged off
      expect(statusBar.find('#spark-login-status a')).toExist()
      expect(statusBar.find('#spark-current-core').hasClass('hidden')).toBe(true)


    it 'checks if username of logged in user is shown', ->
      statusBar = atom.workspaceView.statusBar.find('#spark-dev-status-bar-view')
      # Previously logged out user
      expect(statusBar.find('#spark-login-status a')).toExist()
      # Log user in
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      # Refresh UI
      sparkIde.statusView.updateLoginStatus()

      expect(statusBar.find('#spark-login-status a')).not.toExist()
      expect(statusBar.find('#spark-login-status').text()).toEqual('foo@bar.baz')

      expect(statusBar.find('#spark-current-core').hasClass('hidden')).toBe(false)
      expect(statusBar.find('#spark-current-core a').text()).toBe('No cores selected')

      SettingsHelper.clearCredentials()


    it 'checks current core name', ->
      statusBar = atom.workspaceView.statusBar.find('#spark-dev-status-bar-view')

      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      SparkStub.stubSuccess spark, 'getAttributes'

      spyOn statusView, 'getCurrentCoreStatus'
      sparkIde.statusView.updateCoreStatus()
      expect(statusBar.find('#spark-current-core a').text()).toBe('Foo')
      expect(statusView.getCurrentCoreStatus).toHaveBeenCalled()

      SettingsHelper.clearCurrentCore()
      SettingsHelper.clearCredentials()
      jasmine.unspy statusView, 'getCurrentCoreStatus'


    it 'checks current core name when its null', ->
      statusBar = atom.workspaceView.statusBar.find('#spark-dev-status-bar-view')

      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', null
      SparkStub.stubNullName spark, 'getAttributes'

      spyOn statusView, 'getCurrentCoreStatus'
      sparkIde.statusView.updateCoreStatus()
      expect(statusBar.find('#spark-current-core a').text()).toBe('Unnamed')
      expect(statusView.getCurrentCoreStatus).toHaveBeenCalled()

      SettingsHelper.clearCurrentCore()
      SettingsHelper.clearCredentials()
      jasmine.unspy statusView, 'getCurrentCoreStatus'


    it 'checks current core status', ->
      # Check async core status checking
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      SparkStub.stubSuccess spark, 'getAttributes'

      statusView.getCurrentCoreStatus()

      waitsFor ->
        !statusView.getAttributesPromise

      runs ->
        statusBar = atom.workspaceView.statusBar.find('#spark-dev-status-bar-view')
        expect(statusBar.find('#spark-current-core').hasClass('online')).toBe(true)

        variables = SettingsHelper.getLocal('variables')
        expect(variables).not.toBe(null)
        expect(Object.keys(variables).length).toEqual(1)
        expect(variables.foo).toEqual('int32')

        functions = SettingsHelper.getLocal('functions')
        expect(functions).not.toBe(null)
        expect(functions.length).toEqual(1)
        expect(functions[0]).toEqual('bar')

        SparkStub.stubOffline spark, 'getAttributes'

        statusView.getCurrentCoreStatus()

      waitsFor ->
        !statusView.getAttributesPromise

      runs ->
        statusBar = atom.workspaceView.statusBar.find('#spark-dev-status-bar-view')
        expect(statusBar.find('#spark-current-core').hasClass('online')).toBe(false)
        clearInterval statusView.interval

        SettingsHelper.clearCurrentCore()
        SettingsHelper.clearCredentials()

    it 'checks compile status', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      statusBarItem = atom.workspaceView.statusBar.find('#spark-compile-status')
      statusBarView = atom.workspaceView.statusBar.find('#spark-dev-status-bar-view').view()
      spyOn(SettingsHelper, 'get').andReturn null
      sparkIde.statusView.updateCompileStatus()
      expect(statusBarItem.hasClass('hidden')).toBe(true)
      jasmine.unspy SettingsHelper, 'get'

      # Test compiling in progress
      SettingsHelper.setLocal 'compile-status', {working:true}
      sparkIde.statusView.updateCompileStatus()
      expect(statusBarItem.hasClass('hidden')).toBe(false)
      expect(statusBarItem.find('#spark-compile-working').css('display')).not.toBe('none')
      expect(statusBarItem.find('#spark-compile-failed').css('display')).toBe('none')
      expect(statusBarItem.find('#spark-compile-success').css('display')).toBe('none')

      # Test errors
      SettingsHelper.setLocal 'compile-status', {errors:[1]}
      sparkIde.statusView.updateCompileStatus()
      expect(statusBarItem.hasClass('hidden')).toBe(false)
      expect(statusBarItem.find('#spark-compile-working').css('display')).toBe('none')
      expect(statusBarItem.find('#spark-compile-failed').css('display')).not.toBe('none')
      expect(statusBarItem.find('#spark-compile-success').css('display')).toBe('none')
      expect(statusBarItem.find('#spark-compile-failed').text()).toBe('One error')

      # Test error
      SettingsHelper.setLocal 'compile-status', {error:'Foo'}
      sparkIde.statusView.updateCompileStatus()
      expect(statusBarItem.hasClass('hidden')).toBe(false)
      expect(statusBarItem.find('#spark-compile-working').css('display')).toBe('none')
      expect(statusBarItem.find('#spark-compile-failed').css('display')).not.toBe('none')
      expect(statusBarItem.find('#spark-compile-success').css('display')).toBe('none')
      expect(statusBarItem.find('#spark-compile-failed').text()).toBe('Foo')

      # Test multiple errors
      SettingsHelper.setLocal 'compile-status', {errors:[1,2]}
      sparkIde.statusView.updateCompileStatus()
      expect(statusBarItem.find('#spark-compile-failed').text()).toBe('2 errors')

      # Test clicking on error
      spyOn statusBarView, 'showErrors'
      expect(statusBarView.showErrors).not.toHaveBeenCalled()
      statusBarItem.find('#spark-compile-failed').click()
      expect(statusBarView.showErrors).toHaveBeenCalled()
      jasmine.unspy statusBarView, 'showErrors'

      # Test complete
      SettingsHelper.setLocal 'compile-status', {filename:'foo.bin'}
      sparkIde.statusView.updateCompileStatus()
      expect(statusBarItem.hasClass('hidden')).toBe(false)
      expect(statusBarItem.find('#spark-compile-working').css('display')).toBe('none')
      expect(statusBarItem.find('#spark-compile-failed').css('display')).toBe('none')
      expect(statusBarItem.find('#spark-compile-success').css('display')).not.toBe('none')
      expect(statusBarItem.find('#spark-compile-success').text()).toBe('Success! Firmware saved to foo.bin')

      # Test clicking on filename
      spyOn statusBarView, 'showFile'
      expect(statusBarView.showFile).not.toHaveBeenCalled()
      statusBarItem.find('#spark-compile-success').click()
      expect(statusBarView.showFile).toHaveBeenCalled()
      jasmine.unspy statusBarView, 'showFile'

      SettingsHelper.setLocal 'compile-status', null
      SettingsHelper.clearCredentials()

  it 'checks link commands', ->
    sparkIde.statusView.updateLoginStatus()
    spyOn atom.workspaceView, 'trigger'

    sparkIde.statusView.find('#spark-login-status a').click()
    expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-dev:login')

    SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
    atom.workspaceView.trigger.reset()

    sparkIde.statusView.find('#spark-current-core a').click()
    expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-dev:select-device')

    jasmine.unspy atom.workspaceView, 'trigger'
    SettingsHelper.clearCredentials()
