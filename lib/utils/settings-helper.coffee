settingsPath = '../vendor/settings'
module.exports =
  getProfile: ->
    delete require.cache[require.resolve(settingsPath)]

    settings = require settingsPath
    settings.profile

  setProfile: (profileName) ->
    settings = require settingsPath
    settings.switchProfile(profileName)

  set: (key, value) ->
    delete require.cache[require.resolve(settingsPath)]

    settings = require settingsPath
    settings.override null, key, value

  get: (key) ->
    delete require.cache[require.resolve(settingsPath)]

    settings = require settingsPath
    settings[key]

  setCredentials: (username, access_token) ->
    @set 'username', username
    @set 'access_token', access_token

  clearCredentials: ->
    @set 'username', null
    @set 'access_token', null

  isLoggedIn: ->
    !!@get('access_token')

  setCurrentCore: (id, name) ->
    @set 'current_core', id
    @set 'current_core_name', name

  clearCurrentCore: ->
    @set 'current_core', null
    @set 'current_core_name', null

  hasCurrentCore: ->
    !!@get('current_core')
