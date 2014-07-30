{View} = require 'atom'
$ = require('atom').$

module.exports =
class SparkIdeStatusBarView extends View
  @content: ->
    @div class: 'inline-block', id: 'spark-ide-status-bar-view', =>
      @img src: 'atom://spark-ide/images/spark.png', id: 'spark-icon'
      @span id: 'spark-login-status'
      @span id: 'spark-log'

  initialize: (serializeState) ->
    if atom.workspaceView.statusBar
      @attach()
    else
      @subscribe atom.packages.once 'activated', @attach

    atom.workspaceView.command 'spark-ide:updateLoginStatus', => @updateLoginStatus()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  attach: =>
    atom.workspaceView.statusBar.appendLeft(this)
    @updateLoginStatus()

  # Tear down any state and detach
  destroy: ->
    @remove()

  updateLoginStatus: ->
    settings = require './settings'
    hasToken = !!settings.access_token
    statusElement = this.find('#spark-login-status')
    statusElement.empty()
    
    if hasToken
      statusElement.text(settings.username)
    else
      loginButton = $('<a/>').text('Click to log in to Spark Cloud...')
      statusElement.append(loginButton)
      loginButton.on 'click', =>
        atom.workspaceView.trigger 'spark-ide:login'

  setStatus: (text, type = null) ->
      el = this.find('.spark-log')
      el.text(text)
        .removeClass()

      if type
        el.addClass('text-' + type)

  clear: ->
    el = this.find('.spark-log')
    self = @
    el.fadeOut ->
      self.setStatus ''
      el.show()
