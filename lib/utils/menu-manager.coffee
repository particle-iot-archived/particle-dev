SettingsHelper = require './settings-helper'

module.exports =
  # Get root menu
  getMenu: ->
    devMenu = atom.menu.template.filter (value) ->
      value.label == 'Spark'

    devMenu[0]

  # Update menu
  update: ->
    devMenu = @getMenu()

    if SettingsHelper.isLoggedIn()
      # Menu items for logged in user
      username = SettingsHelper.get('username')

      devMenu.submenu = [{
        label: 'Log out ' + username,
        command: 'spark-dev:logout'
      },{
        type: 'separator'
      },{
        label: 'Select device...',
        command: 'spark-dev:select-device'
      }]

      if SettingsHelper.hasCurrentCore()
        # Menu items depending on current core
        devMenu.submenu = devMenu.submenu.concat [{
          label: 'Rename ' + SettingsHelper.getLocal('current_core_name') + '...',
          command: 'spark-dev:rename-device'
        },{
          label: 'Remove ' + SettingsHelper.getLocal('current_core_name') + '...',
          command: 'spark-dev:remove-device'
        },{
          label: 'Flash ' + SettingsHelper.getLocal('current_core_name') + ' via the cloud',
          command: 'spark-dev:flash-cloud'
        }]

      devMenu.submenu = devMenu.submenu.concat [{
        type: 'separator'
      },{
        label: 'Claim device...',
        command: 'spark-dev:claim-device'
      },{
        label: 'Identify device...',
        command: 'spark-dev:identify-device'
      },{
        label: 'Setup device\'s WiFi...',
        command: 'spark-dev:setup-wifi'
      },{
      #   label: 'Flash device via USB',
      #   command: 'spark-dev:try-flash-usb'
      # },{
        type: 'separator'
      },{
        label: 'Compile in the cloud',
        command: 'spark-dev:compile-cloud'
      }]
    else
      # Logged out user can only log in
      devMenu.submenu = [{
        label: 'Log in to Spark Cloud...',
        command: 'spark-dev:login'
      }]

    devMenu.submenu = devMenu.submenu.concat [{
      type: 'separator'
    },{
      label: 'Show serial monitor',
      command: 'spark-dev:show-serial-monitor'
    }]

    # Refresh UI
    atom.menu.update()

  append: (items) ->
    devMenu = @getMenu()
    devMenu.submenu = devMenu.submenu.concat items
    atom.menu.update()
