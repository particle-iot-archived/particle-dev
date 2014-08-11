module.exports =
  getProfile: ->
    delete require.cache[require.resolve('./settings')]

    settings = require './settings'
    settings.profile

  setProfile: (profileName) ->
    settings = require './settings'
    settings.switchProfile(profileName)

  set: (key, value) ->
    settings = require './settings'
    settings.override null, key, value

  get: (key) ->
    delete require.cache[require.resolve('./settings')]

    settings = require './settings'
    settings[key]

  setCredentials: (username, access_token) ->
    @set 'username', username
    @set 'access_token', access_token

  clearCredentials: ->
    @set 'username', null
    @set 'access_token', null

  loggedIn: ->
    !!@get('access_token')

  setCurrentCore: (id, name) ->
    @set 'current_core', id
    @set 'current_core_name', name

  clearCurrentCore: ->
    @set 'current_core', null
    @set 'current_core_name', null
