SettingsHelper = require '../../lib/utils/settings-helper'
SparkStub = require('spark-dev-spec-stubs').spark
spark = require 'spark'

describe 'Status Bar Tests', ->
  activationPromise = null
  statusBarPromise = null
  originalProfile = null
  sparkIde = null
  statusView = null
  workspaceElement = null

  beforeEach ->
    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-dev-test'

    SparkStub.stubSuccess spark, 'getAttributes'

    workspaceElement = atom.views.getView(atom.workspace)
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
      expect(statusView).toExist()
      expect(statusView.find('#spark-icon').is(':empty')).toBe(true)
      # User should be logged off
      expect(statusView.find('#spark-login-status a')).toExist()
      expect(statusView.find('#spark-current-core').hasClass('hidden')).toBe(true)


    it 'checks if username of logged in user is shown', ->
      # Previously logged out user
      expect(statusView.find('#spark-login-status a')).toExist()
      # Log user in
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      # Refresh UI
      sparkIde.statusView.updateLoginStatus()

      expect(statusView.find('#spark-login-status a')).not.toExist()
      expect(statusView.find('#spark-login-status').text()).toEqual('foo@bar.baz')

      expect(statusView.find('#spark-current-core').hasClass('hidden')).toBe(false)
      expect(statusView.find('#spark-current-core a').text()).toBe('No devices selected')

      SettingsHelper.clearCredentials()


    it 'checks current core name', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      SparkStub.stubSuccess spark, 'getAttributes'

      spyOn statusView, 'getCurrentCoreStatus'
      sparkIde.statusView.updateCoreStatus()
      expect(statusView.find('#spark-current-core a').text()).toBe('Foo')
      expect(statusView.getCurrentCoreStatus).toHaveBeenCalled()

      SettingsHelper.clearCurrentCore()
      SettingsHelper.clearCredentials()
      jasmine.unspy statusView, 'getCurrentCoreStatus'


    it 'checks current core name when its null', ->
      statusBar = statusView.find('#spark-dev-status-bar-view')

      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', null
      SparkStub.stubNullName spark, 'getAttributes'

      spyOn statusView, 'getCurrentCoreStatus'
      sparkIde.statusView.updateCoreStatus()
      expect(statusView.find('#spark-current-core a').text()).toBe('Unnamed')
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
        expect(statusView.find('#spark-current-core').hasClass('online')).toBe(true)

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
        expect(statusView.find('#spark-current-core').hasClass('online')).toBe(false)
        clearInterval statusView.interval

        SettingsHelper.clearCurrentCore()
        SettingsHelper.clearCredentials()

    it 'checks compile status', ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      statusBarItem = statusView.find('#spark-compile-status')
      spyOn(SettingsHelper, 'get').andReturn null
      sparkIde.statusView.updateCompileStatus()
      expect(statusBarItem.hasClass('hidden')).toBe(true)
      jasmine.unspy SettingsHelper, 'get'

      # Test compiling in progress
      SettingsHelper.setLocal 'compile-status', {working:true}
      statusView.updateCompileStatus()
      expect(statusBarItem.hasClass('hidden')).toBe(false)
      expect(statusBarItem.find('#spark-compile-working').css('display')).not.toBe('none')
      expect(statusBarItem.find('#spark-compile-failed').css('display')).toBe('none')
      expect(statusBarItem.find('#spark-compile-success').css('display')).toBe('none')

      # Test errors
      SettingsHelper.setLocal 'compile-status', {errors:[1]}
      statusView.updateCompileStatus()
      expect(statusBarItem.hasClass('hidden')).toBe(false)
      expect(statusBarItem.find('#spark-compile-working').css('display')).toBe('none')
      expect(statusBarItem.find('#spark-compile-failed').css('display')).not.toBe('none')
      expect(statusBarItem.find('#spark-compile-success').css('display')).toBe('none')
      expect(statusBarItem.find('#spark-compile-failed').text()).toBe('One error')

      # Test error
      SettingsHelper.setLocal 'compile-status', {error:'Foo'}
      statusView.updateCompileStatus()
      expect(statusBarItem.hasClass('hidden')).toBe(false)
      expect(statusBarItem.find('#spark-compile-working').css('display')).toBe('none')
      expect(statusBarItem.find('#spark-compile-failed').css('display')).not.toBe('none')
      expect(statusBarItem.find('#spark-compile-success').css('display')).toBe('none')
      expect(statusBarItem.find('#spark-compile-failed').text()).toBe('Foo')

      # Test multiple errors
      SettingsHelper.setLocal 'compile-status', {errors:[1,2]}
      statusView.updateCompileStatus()
      expect(statusBarItem.find('#spark-compile-failed').text()).toBe('2 errors')

      # Test clicking on error
      spyOn statusView, 'showErrors'
      expect(statusView.showErrors).not.toHaveBeenCalled()
      statusBarItem.find('#spark-compile-failed').click()
      expect(statusView.showErrors).toHaveBeenCalled()
      jasmine.unspy statusView, 'showErrors'

      # Test complete
      SettingsHelper.setLocal 'compile-status', {filename:'foo.bin'}
      statusView.updateCompileStatus()
      expect(statusBarItem.hasClass('hidden')).toBe(false)
      expect(statusBarItem.find('#spark-compile-working').css('display')).toBe('none')
      expect(statusBarItem.find('#spark-compile-failed').css('display')).toBe('none')
      expect(statusBarItem.find('#spark-compile-success').css('display')).not.toBe('none')
      expect(statusBarItem.find('#spark-compile-success').text()).toBe('Success! Firmware saved to foo.bin')

      # Test clicking on filename
      spyOn statusView, 'showFile'
      expect(statusView.showFile).not.toHaveBeenCalled()
      statusBarItem.find('#spark-compile-success').click()
      expect(statusView.showFile).toHaveBeenCalled()
      jasmine.unspy statusView, 'showFile'

      SettingsHelper.setLocal 'compile-status', null
      SettingsHelper.clearCredentials()

  it 'checks link commands', ->
    statusView.updateLoginStatus()
    spyOn atom.commands, 'dispatch'

    statusView.find('#spark-login-status a').click()
    expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, 'spark-dev:login')

    SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
    atom.commands.dispatch.reset()

    statusView.find('#spark-current-core a').click()
    expect(atom.commands.dispatch).toHaveBeenCalledWith(workspaceElement, 'spark-dev:select-device')

    jasmine.unspy atom.commands, 'dispatch'
    SettingsHelper.clearCredentials()
