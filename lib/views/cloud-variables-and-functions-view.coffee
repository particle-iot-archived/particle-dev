{View, TextEditorView} = require 'atom'
{Emitter} = require 'event-kit'
$ = null
$$ = null
whenjs = require 'when'
SettingsHelper = null
Subscriber = null
spark = null

module.exports =
class CloudVariablesAndFunctionsView extends View
  @content: ->
    @div id: 'spark-dev-cloud-variables-and-functions', =>
      @div id: 'spark-dev-cloud-variables', class: 'panel', =>
        @div class: 'panel-heading', 'Variables'
        @div class: 'panel-body padded', outlet: 'variables'
      @div id: 'spark-dev-cloud-functions', class: 'panel', =>
        @div class: 'panel-heading', 'Functions'
        @div class: 'panel-body padded', outlet: 'functions'

  initialize: (serializeState) ->
    {$, $$} = require 'atom'
    {Subscriber} = require 'emissary'
    SettingsHelper = require '../utils/settings-helper'
    spark = require 'spark'
    spark.login { accessToken: SettingsHelper.get('access_token') }

    @emitter = new Emitter
    @subscriber = new Subscriber()
    # Show some progress when core's status is downloaded
    @subscriber.subscribeToCommand atom.workspaceView, 'spark-dev:update-core-status', =>
      @variables.empty()
      @functions.empty()
      @addClass 'loading'

    @subscriber.subscribeToCommand atom.workspaceView, 'spark-dev:core-status-updated', =>
      # Refresh UI and watchers when current core changes
      @listVariables()
      @listFunctions()
      @clearWatchers()
      @removeClass 'loading'

    @subscriber.subscribeToCommand atom.workspaceView, 'spark-dev:logout', =>
      # Clear watchers and hide when user logs out
      @clearWatchers()
      @close()

    @client = null
    @watchers = {}
    @variablePromises = {}

    @listVariables()
    @listFunctions()

  serialize: ->

  getTitle: ->
    'Cloud variables & functions'

  onDidChangeTitle: (callback) ->
    @emitter.on 'did-change-title', callback

  onDidChangeModified: (callback) ->
    @emitter.on 'did-change-modified', callback

  getUri: ->
    'spark-dev://editor/cloud-variables-and-functions'

  close: ->
    pane = atom.workspace.paneForUri @getUri()
    pane?.destroy()

  # Propagate table with variables
  listVariables: ->
    variables = SettingsHelper.get 'variables'
    @variables.empty()

    if !variables || Object.keys(variables).length == 0
      @variables.append $$ ->
        @ul class: 'background-message', =>
          @li 'No variables registered'
    else
      table = $$ ->
        @table =>
          @thead =>
            @tr =>
              @th 'Name'
              @th 'Type'
              @th 'Value'
              @th 'Refresh'
              @th 'Watch'
          @tbody =>
            @raw ''

      for variable in Object.keys(variables)
        row = $$ ->
          @table =>
            @tr 'data-id': variable, =>
              @td variable
              @td variables[variable]
              @td class: 'loading'
              @td =>
                @button class: 'btn btn-sm icon icon-sync'
              @td =>
                @button class: 'btn btn-sm icon icon-eye'

        row.find('td:eq(3) button').on 'click', (event) =>
          @refreshVariable $(event.currentTarget).parent().parent().attr('data-id')

        row.find('td:eq(4) button').on 'click', (event) =>
          @toggleWatchVariable $(event.currentTarget).parent().parent().attr('data-id')

        table.find('tbody').append row.find('tbody >')

      @variables.append table

      # Get initial values
      for variable in Object.keys(variables)
        @refreshVariable variable

  # Get variable value from the cloud
  refreshVariable: (variableName) ->
    dfd = whenjs.defer()

    cell = @find('#spark-dev-cloud-variables [data-id=' + variableName + '] td:eq(2)')
    cell.addClass 'loading'
    cell.text ''
    promise = @variablePromises[variableName]
    if !!promise
      promise._handler.resolve()
    promise = spark.getVariable SettingsHelper.get('current_core'), variableName
    @variablePromises[variableName] = promise
    promise.done (e) =>
      if !e
        dfd.resolve null
        return
        
      delete @variablePromises[variableName]
      cell.removeClass()

      if !!e.ok
        cell.addClass 'icon icon-issue-opened text-error'
        dfd.reject()
      else
        cell.text e.result
        dfd.resolve e.result
    , (e) =>
      delete @variablePromises[variableName]
      cell.removeClass()
      cell.addClass 'icon icon-issue-opened text-error'
      dfd.reject()
    dfd.promise

  # Toggle watching variable
  toggleWatchVariable: (variableName) ->
    row = @find('#spark-dev-cloud-variables [data-id=' + variableName + ']')
    watchButton = row.find('td:eq(4) button')
    refreshButton = row.find('td:eq(3) button')
    valueCell = row.find('td:eq(2)')

    if watchButton.hasClass 'selected'
      watchButton.removeClass 'selected'
      refreshButton.removeAttr 'disabled'
      clearInterval @watchers[variableName]
      delete @watchers[variableName]
    else
      watchButton.addClass 'selected'
      refreshButton.attr 'disabled', 'disabled'
      # Gget variable every 5 seconds (empirical value)
      @watchers[variableName] = setInterval =>
        @refreshVariable variableName
      , 5000

  # Remove all variable watchers
  clearWatchers: ->
    for key in Object.keys(@watchers)
      clearInterval @watchers[key]
    @watchers = {}

  # Propagate table with functions
  listFunctions: ->
    functions = SettingsHelper.get 'functions'

    @functions.empty()
    if !functions || functions.length == 0
      @functions.append $$ ->
        @ul class: 'background-message', =>
          @li 'No functions registered'
    else
      for func in functions
        row = $$ ->
          @div 'data-id': func, =>
            @button class: 'btn icon icon-zap', func
            @span '('
            @subview 'parameters', new TextEditorView(mini: true, placeholderText: 'Parameters')
            @span ') == '
            @subview 'result', new TextEditorView(mini: true, placeholderText: 'Result')
            @span class: 'three-quarters inline-block hidden'
        row.find('button').on 'click', (event) =>
          @callFunction $(event.currentTarget).parent().attr('data-id')
        row.find('.editor:eq(0)').view().on 'core:confirm', (event) =>
          @callFunction $(event.currentTarget).parent().attr('data-id')
        row.find('.editor:eq(1)').view().hiddenInput.attr 'disabled', 'disabled'
        @functions.append row

  # Lock/unlock row
  setRowEnabled: (row, enabled) ->
    if enabled
      row.find('button').removeAttr 'disabled'
      row.find('.editor:eq(0)').view().hiddenInput.removeAttr 'disabled'
      row.find('.three-quarters').addClass 'hidden'
    else
      row.find('button').attr 'disabled', 'disabled'
      row.find('.editor:eq(0)').view().hiddenInput.attr 'disabled', 'disabled'
      row.find('.three-quarters').removeClass 'hidden'
      row.find('.editor:eq(1)').view().removeClass 'icon icon-issue-opened'

  # Call function via cloud
  callFunction: (functionName) ->
    dfd = whenjs.defer()
    row = @find('#spark-dev-cloud-functions [data-id=' + functionName + ']')
    @setRowEnabled row, false
    row.find('.editor:eq(1)').view().setText ' '
    params = row.find('.editor:eq(0)').view().getText()
    promise = spark.callFunction SettingsHelper.get('current_core'), functionName, params
    promise.done (e) =>
      @setRowEnabled row, true

      if !!e.ok
        row.find('.editor:eq(1)').view().addClass 'icon icon-issue-opened'
        dfd.reject()
      else
        row.find('.editor:eq(1)').view().setText e.return_value.toString()

        dfd.resolve e.return_value
    , (e) =>
      @setRowEnabled row, true
      row.find('.editor:eq(1)').view().addClass 'icon icon-issue-opened'

      dfd.reject()
    dfd.promise
