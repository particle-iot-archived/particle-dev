{WorkspaceView} = require 'atom'
MenuManager = require '../../lib/utils/menu-manager'
SettingsHelper = require '../../lib/utils/settings-helper'

describe 'MenuManager tests', ->
  activationPromise = null
  originalProfile = null

  beforeEach ->
    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-dev-test'

    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-dev')

  afterEach ->
    SettingsHelper.setProfile originalProfile

  it 'checks menu for logged out user', ->
    waitsForPromise ->
      activationPromise

    runs ->
      ideMenu = MenuManager.getMenu()

      expect(ideMenu.submenu.length).toBe(3)

      expect(ideMenu.submenu[0].label).toBe('Log in to Spark Cloud...')
      expect(ideMenu.submenu[0].command).toBe('spark-dev:login')

      expect(ideMenu.submenu[1].type).toBe('separator')

      expect(ideMenu.submenu[2].label).toBe('Show serial monitor')
      expect(ideMenu.submenu[2].command).toBe('spark-dev:show-serial-monitor')


  it 'checks menu for logged in user', ->
    waitsForPromise ->
      activationPromise

    runs ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      # Refresh UI
      atom.workspaceView.trigger 'spark-dev:update-menu'

      ideMenu = MenuManager.getMenu()

      expect(ideMenu.submenu.length).toBe(11)

      expect(ideMenu.submenu[0].label).toBe('Log out foo@bar.baz')
      expect(ideMenu.submenu[0].command).toBe('spark-dev:logout')

      expect(ideMenu.submenu[1].type).toBe('separator')

      expect(ideMenu.submenu[2].label).toBe('Select device...')
      expect(ideMenu.submenu[2].command).toBe('spark-dev:select-device')

      expect(ideMenu.submenu[3].type).toBe('separator')

      expect(ideMenu.submenu[4].label).toBe('Claim device...')
      expect(ideMenu.submenu[4].command).toBe('spark-dev:claim-device')

      expect(ideMenu.submenu[5].label).toBe('Identify device...')
      expect(ideMenu.submenu[5].command).toBe('spark-dev:identify-device')

      expect(ideMenu.submenu[6].label).toBe('Setup device\'s WiFi...')
      expect(ideMenu.submenu[6].command).toBe('spark-dev:setup-wifi')

      expect(ideMenu.submenu[7].type).toBe('separator')

      expect(ideMenu.submenu[8].label).toBe('Compile in the cloud')
      expect(ideMenu.submenu[8].command).toBe('spark-dev:compile-cloud')

      expect(ideMenu.submenu[9].type).toBe('separator')

      expect(ideMenu.submenu[10].label).toBe('Show serial monitor')
      expect(ideMenu.submenu[10].command).toBe('spark-dev:show-serial-monitor')

      SettingsHelper.clearCredentials()

  it 'checks menu for selected device', ->
    waitsForPromise ->
      activationPromise

    runs ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      atom.workspaceView.trigger 'spark-dev:update-menu'

      ideMenu = MenuManager.getMenu()

      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      atom.workspaceView.trigger 'spark-dev:update-menu'

      ideMenu = MenuManager.getMenu()

      expect(ideMenu.submenu.length).toBe(15)

      expect(ideMenu.submenu[3].label).toBe('Rename Foo...')
      expect(ideMenu.submenu[3].command).toBe('spark-dev:rename-device')

      expect(ideMenu.submenu[4].label).toBe('Remove Foo...')
      expect(ideMenu.submenu[4].command).toBe('spark-dev:remove-device')

      expect(ideMenu.submenu[5].label).toBe('Show cloud variables and functions')
      expect(ideMenu.submenu[5].command).toBe('spark-dev:show-cloud-variables-and-functions')

      expect(ideMenu.submenu[6].label).toBe('Flash Foo via the cloud')
      expect(ideMenu.submenu[6].command).toBe('spark-dev:flash-cloud')

      SettingsHelper.clearCurrentCore()
      SettingsHelper.clearCredentials()
