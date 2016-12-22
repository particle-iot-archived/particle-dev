SettingsHelper = require './settings-helper'
packageName = require './package-helper'

module.exports =
  # Get root menu
  getMenu: ->
    devMenu = atom.menu.template.filter (value) ->
      value.label == 'Particle'

    devMenu[0]

  # Update menu
  update: ->
    devMenu = @getMenu()

    if SettingsHelper.isLoggedIn()
      # Menu items for logged in user
      username = SettingsHelper.get('username')

      devMenu.submenu = [{
        label: 'Log out ' + username,
        command: "#{packageName()}:logout"
      },{
        type: 'separator'
      },{
        label: 'Select device...',
        command: "#{packageName()}:select-device"
      }]

      if SettingsHelper.hasCurrentCore()
        currentCoreName = SettingsHelper.getLocal('current_core_name')
        if !currentCoreName
          currentCoreName = 'Unnamed'
        # Menu items depending on current core
        devMenu.submenu = devMenu.submenu.concat [{
          label: "Rename #{currentCoreName}...",
          command: "#{packageName()}:rename-device"
        },{
          label: "Remove #{currentCoreName}...",
          command: "#{packageName()}:remove-device"
        },{
          label: "Flash #{currentCoreName} via the cloud",
          command: "#{packageName()}:flash-cloud"
        }]

      devMenu.submenu = devMenu.submenu.concat [{
        type: 'separator'
      },{
        label: 'Claim device...',
        command: "#{packageName()}:claim-device"
      },{
        label: 'Identify device...',
        command: "#{packageName()}:identify-device"
      },{
      #   label: "Setup device's WiFi...",
      #   command: "#{packageName()}:setup-wifi"
      # },{
      #   label: 'Flash device via USB',
      #   command: "#{packageName()}:try-flash-usb"
      # },{
        type: 'separator'
      },{
        label: 'Compile in the cloud',
        command: "#{packageName()}:compile-cloud"
      }]
    else
      # Logged out user can only log in
      devMenu.submenu = [{
        label: 'Log in to Particle Cloud...',
        command: "#{packageName()}:login"
      }]

    devMenu.submenu = devMenu.submenu.concat [{
      type: 'separator'
    },{
      label: 'Show serial monitor',
      command: "#{packageName()}:show-serial-monitor"
    }]

    # Refresh UI
    atom.menu.update()

    @workspaceElement = atom.views.getView(atom.workspace)
    atom.commands.dispatch @workspaceElement, "#{packageName()}:append-menu"

  append: (items) ->
    devMenu = @getMenu()
    devMenu.submenu = devMenu.submenu.concat items
    atom.menu.update()
