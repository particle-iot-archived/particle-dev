SettingsHelper = require './settings-helper'

module.exports =
  getMenu: ->
    ideMenu = atom.menu.template.filter (value) ->
      value.label == 'Spark IDE'

    ideMenu[0]

  update: ->
    ideMenu = atom.menu.template.filter (value) ->
      value.label == 'Spark IDE'

    ideMenu = @getMenu()

    if SettingsHelper.isLoggedIn()
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
        ideMenu.submenu = ideMenu.submenu.concat [{
          label: 'Rename ' + SettingsHelper.get('current_core_name') + '...',
          command: 'spark-ide:rename-core'
        },{
          label: 'Remove ' + SettingsHelper.get('current_core_name') + '...',
          command: 'spark-ide:remove-core'
        },{
          label: 'Toggle cloud variables and functions',
          command: 'spark-ide:toggle-cloud-variables-and-functions'
        },{
          label: 'Flash ' + SettingsHelper.get('current_core_name') + ' via cloud',
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
        type: 'separator'
      },{
        label: 'Compile in the cloud',
        command: 'spark-ide:compile-cloud'
      }]
    else
      ideMenu.submenu = [{
        label: 'Log in to Spark Cloud...',
        command: 'spark-ide:login'
      }]

    atom.menu.update()
