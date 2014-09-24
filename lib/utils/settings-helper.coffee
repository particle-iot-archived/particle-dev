settingsPath = '../vendor/settings'
module.exports =
  # Get current profile
  getProfile: ->
    # Remove settings.js from require's cache
    delete require.cache[require.resolve(settingsPath)]

    settings = require settingsPath
    settings.profile

  # Set current profile
  setProfile: (profileName) ->
    settings = require settingsPath
    settings.switchProfile(profileName)

  # Set key to value
  set: (key, value) ->
    delete require.cache[require.resolve(settingsPath)]

    settings = require settingsPath
    settings.override null, key, value

  # Get key's value
  get: (key) ->
    delete require.cache[require.resolve(settingsPath)]

    settings = require settingsPath
    settings[key]

  # Set username and access token
  setCredentials: (username, access_token) ->
    @set 'username', username
    @set 'access_token', access_token

  # Clear username and access token
  clearCredentials: ->
    @set 'username', null
    @set 'access_token', null

  # True if there is access token saved
  isLoggedIn: ->
    !!@get('access_token')

  # Set current core's ID and name
  setCurrentCore: (id, name) ->
    @set 'current_core', id
    @set 'current_core_name', name

  # Clear current core
  clearCurrentCore: ->
    @set 'current_core', null
    @set 'current_core_name', null

  # True if there is current core set
  hasCurrentCore: ->
    !!@get('current_core')
