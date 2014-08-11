SettingsHelper = require './settings-helper'

module.exports =
  update: ->
    ideMenu = atom.menu.template.filter (value) ->
      value.label == 'Spark IDE'

    ideMenu = ideMenu[0]

    if SettingsHelper.loggedIn()
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
    else
      ideMenu.submenu = [{
        label: 'Log in to Spark Cloud...',
        command: 'spark-ide:login'
      }]

    atom.menu.update()
