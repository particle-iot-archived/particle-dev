SettingsHelper = require './settings-helper'

module.exports =
  # Get root menu
  getMenu: ->
    ideMenu = atom.menu.template.filter (value) ->
      value.label == 'Spark'

    ideMenu[0]

  # Update menu
  update: ->
    ideMenu = @getMenu()

    if SettingsHelper.isLoggedIn()
      # Menu items for logged in user
      username = SettingsHelper.get('username')

      ideMenu.submenu = [{
        label: 'Log out ' + username,
        command: 'spark-ide:logout'
      },{
        type: 'separator'
      },{
        label: 'Select Core...',
        command: 'spark-ide:select-core'
      }]

      if SettingsHelper.hasCurrentCore()
        # Menu items depending on current core
        ideMenu.submenu = ideMenu.submenu.concat [{
          label: 'Rename ' + SettingsHelper.get('current_core_name') + '...',
          command: 'spark-ide:rename-core'
        },{
          label: 'Remove ' + SettingsHelper.get('current_core_name') + '...',
          command: 'spark-ide:remove-core'
        },{
          label: 'Show cloud variables and functions',
          command: 'spark-ide:show-cloud-variables-and-functions'
        },{
          label: 'Flash ' + SettingsHelper.get('current_core_name') + ' via the cloud',
          command: 'spark-ide:flash-cloud'
        }]

      ideMenu.submenu = ideMenu.submenu.concat [{
        type: 'separator'
      },{
        label: 'Claim Core...',
        command: 'spark-ide:claim-core'
      },{
        label: 'Identify Core...',
        command: 'spark-ide:identify-core'
      },{
        label: 'Setup Core\'s WiFi...',
        command: 'spark-ide:setup-wifi'
      },{
        type: 'separator'
      },{
        label: 'Compile in the cloud',
        command: 'spark-ide:compile-cloud'
      }]
    else
      # Logged out user can only log in
      ideMenu.submenu = [{
        label: 'Log in to Spark Cloud...',
        command: 'spark-ide:login'
      }]

    ideMenu.submenu = ideMenu.submenu.concat [{
      type: 'separator'
    },{
      label: 'Show serial monitor',
      command: 'spark-ide:show-serial-monitor'
    }]

    # Refresh UI
    atom.menu.update()
