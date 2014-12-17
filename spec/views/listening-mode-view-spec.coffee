{WorkspaceView} = require 'atom'
$ = require('atom').$
SettingsHelper = require '../../lib/utils/settings-helper'
SerialHelper = require '../../lib/utils/serial-helper'
require 'serialport'

describe 'Listening Mode View', ->
  activationPromise = null
  sparkIde = null
  listeningModeView = null
  originalProfile = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-dev').then ({mainModule}) ->
      sparkIde = mainModule
      sparkIde.listeningModeView = null

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-dev-test'

    SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

    # Mock serial
    require.cache[require.resolve('serialport')].exports = require('spark-dev-spec-stubs').serialportNoPorts

    waitsForPromise ->
      activationPromise

  afterEach ->
    SettingsHelper.clearCredentials()
    SettingsHelper.setProfile originalProfile

  describe '', ->
    it 'tests hiding and showing', ->
      # Test core:cancel
      sparkIde.identifyCore()

      waitsFor ->
        !sparkIde.listPortsPromise

      runs ->
        expect(atom.workspaceView.find('#spark-dev-listening-mode-view')).toExist()
        atom.workspaceView.trigger 'core:cancel'
        expect(atom.workspaceView.find('#spark-dev-listening-mode-view')).not.toExist()

        # Test core:close
        sparkIde.identifyCore()

      waitsFor ->
        !sparkIde.listPortsPromise

      runs ->
        expect(atom.workspaceView.find('#spark-dev-listening-mode-view')).toExist()
        atom.workspaceView.trigger 'core:close'
        expect(atom.workspaceView.find('#spark-dev-listening-mode-view')).not.toExist()

        # Test cancel button
        sparkIde.identifyCore()

      waitsFor ->
        !sparkIde.listPortsPromise

      runs ->
        expect(atom.workspaceView.find('#spark-dev-listening-mode-view')).toExist()
        listeningModeView = sparkIde.listeningModeView
        listeningModeView.find('button').click()
        expect(atom.workspaceView.find('#spark-dev-listening-mode-view')).not.toExist()


    it 'tests interval for dialog dismissal', ->
      jasmine.Clock.useMock()
      sparkIde.identifyCore()
      spyOn SerialHelper, 'listPorts'

      waitsFor ->
        !sparkIde.listPortsPromise

      runs ->
        expect(SerialHelper.listPorts).not.toHaveBeenCalled()
        jasmine.Clock.tick(1001)
        expect(SerialHelper.listPorts).toHaveBeenCalled()

        jasmine.unspy SerialHelper, 'listPorts'
        atom.workspaceView.trigger 'core:cancel'
