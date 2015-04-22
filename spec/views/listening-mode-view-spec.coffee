{WorkspaceView, $} = require 'atom-space-pen-views'
SettingsHelper = require '../../lib/utils/settings-helper'
SerialHelper = require '../../lib/utils/serial-helper'
ListeningModeView = require '../../lib/views/listening-mode-view'
require 'serialport'

fdescribe 'Listening Mode View', ->
  activationPromise = null
  sparkIde = null
  listeningModeView = null
  originalProfile = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('spark-dev').then ({mainModule}) ->
      sparkIde = mainModule

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
      listeningModeView = new ListeningModeView()

      # Test core:cancel
      spyOn(listeningModeView.panel, 'show').andCallThrough()
      listeningModeView.show()
      expect(listeningModeView.panel.show).toHaveBeenCalled()

      spyOn(listeningModeView, 'hide').andCallThrough()
      atom.commands.dispatch workspaceElement, 'core:cancel'
      expect(listeningModeView.hide).toHaveBeenCalled()

      # listeningModeView.show()
      # listeningModeView.hide.reset()
      # atom.commands.dispatch workspaceElement, 'core:close'
      # expect(listeningModeView.hide).toHaveBeenCalled()

      listeningModeView.show()
      listeningModeView.hide.reset()
      listeningModeView.find('button').click()
      expect(listeningModeView.hide).toHaveBeenCalled()

      jasmine.unspy listeningModeView.panel, 'show'
      jasmine.unspy listeningModeView, 'hide'
      listeningModeView.cancel()

    it 'tests interval for dialog dismissal', ->
      jasmine.Clock.useMock()
      listeningModeView = new ListeningModeView()
      spyOn SerialHelper, 'listPorts'

      listeningModeView.show()
      expect(SerialHelper.listPorts).not.toHaveBeenCalled()
      jasmine.Clock.tick(1001)
      expect(SerialHelper.listPorts).toHaveBeenCalled()

      jasmine.unspy SerialHelper, 'listPorts'
      listeningModeView.cancel()
