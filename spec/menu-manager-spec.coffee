{WorkspaceView} = require 'atom'
MenuManager = require '../lib/utils/menu-manager'
SettingsHelper = require '../lib/utils/settings-helper'

describe 'MenuManager tests', ->
  activationPromise = null
  originalProfile = null

  beforeEach ->
    require '../lib/vendor/ApiClient'

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-ide-test'

    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide')

  afterEach ->
    SettingsHelper.setProfile originalProfile
    delete require.cache[require.resolve('../lib/vendor/ApiClient')]

  it 'checks menu for logged out user', ->
    waitsForPromise ->
      activationPromise

    runs ->
      ideMenu = atom.menu.template.filter (value) ->
        value.label == 'Spark IDE'
      expect(ideMenu.length).toBe(1)
      expect(ideMenu[0].submenu[0].label).toBe('Log in to Spark Cloud...')
      expect(ideMenu[0].submenu[0].command).toBe('spark-ide:login')


  it 'checks menu for logged in user', ->
    waitsForPromise ->
      activationPromise

    runs ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'

      # Refresh UI
      atom.workspaceView.trigger 'spark-ide:update-menu'

      ideMenu = atom.menu.template.filter (value) ->
        value.label == 'Spark IDE'
      expect(ideMenu.length).toBe(1)

      expect(ideMenu[0].submenu[0].label).toBe('Log out foo@bar.baz')
      expect(ideMenu[0].submenu[0].command).toBe('spark-ide:logout')

      expect(ideMenu[0].submenu[1].type).toBe('separator')

      expect(ideMenu[0].submenu[2].label).toBe('Select Core...')
      expect(ideMenu[0].submenu[2].command).toBe('spark-ide:select-core')

      SettingsHelper.clearCredentials()
