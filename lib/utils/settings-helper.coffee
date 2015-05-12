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

  # Get local (current window's) key's value
  getLocal: (key) ->
    if window.localSettings
      return window.localSettings[key]
    null

  # Set local (current window's) key to value
  setLocal: (key, value) ->
    if !window.localSettings
      window.localSettings = {}

    window.localSettings[key] = value

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
  setCurrentCore: (id, name, platform=0) ->
    @setLocal 'current_core', id
    @setLocal 'current_core_name', name
    @setLocal 'current_core_platform', platform

  # Clear current core
  clearCurrentCore: ->
    @setCurrentCore null, null, null

  # True if there is current core set
  hasCurrentCore: ->
    !!@getLocal('current_core')

  getApiUrl: ->
    @get 'apiUrl'
