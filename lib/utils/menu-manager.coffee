SettingsHelper = require './settings-helper'

module.exports =
  update: ->
    ideMenu = atom.menu.template.filter (value) ->
      value.label == 'Spark IDE'

    ideMenu = ideMenu[0]

    if SettingsHelper.isLoggedIn()
      username = SettingsHelper.get('username')
      # TODO: Check if there is selected core
      ideMenu.submenu = [{
        label: 'Log out ' + username,
        command: 'spark-ide:logout'
      },{
        type: 'separator'
      },{
        label: 'Select Core...',
        command: 'spark-ide:select-core'
      },{
        label: 'Rename Core...',
        command: 'spark-ide:rename-core'
      }]
    else
      ideMenu.submenu = [{
        label: 'Log in to Spark Cloud...',
        command: 'spark-ide:login'
      }]

    atom.menu.update()
