{View, EditorView} = require 'atom'
{Emitter} = require 'event-kit'
$ = null
$$ = null
whenjs = require 'when'
SettingsHelper = null
spark = null

module.exports =
class CloudVariablesAndFunctionsView extends View
  @content: ->
    @div id: 'spark-ide-cloud-variables-and-functions', =>
      @div id: 'spark-ide-cloud-variables', class: 'panel', =>
        @div class: 'panel-heading', 'Variables'
        @div class: 'panel-body padded', outlet: 'variables'
      @div id: 'spark-ide-cloud-functions', class: 'panel', =>
        @div class: 'panel-heading', 'Functions'
        @div class: 'panel-body padded', outlet: 'functions'

  initialize: (serializeState) ->
    {$, $$} = require 'atom'
    SettingsHelper = require '../utils/settings-helper'
    spark = require 'spark'
    spark.login { accessToken: SettingsHelper.get('access_token') }

    @emitter = new Emitter

    @client = null
    @watchers = {}

    # TODO: Support empty variables/functions lists
    @listVariables()
    @listFunctions()

    # Refresh UI and watchers when current core changes
    atom.workspaceView.command 'spark-ide:update-core-status', =>
      @listVariables()
      @listFunctions()
      @clearWatchers()

    # Clear watchers and hide when user logs out
    atom.workspaceView.command 'spark-ide:logout', =>
      @clearWatchers()
      @close()

  serialize: ->

  getTitle: ->
    'Cloud variables & functions'

  onDidChangeTitle: (callback) ->
    @emitter.on 'did-change-title', callback

  onDidChangeModified: (callback) ->
    @emitter.on 'did-change-modified', callback

  getUri: ->
    'spark-ide://editor/cloud-variables-and-functions'

  close: ->
    pane = atom.workspace.paneForUri @getUri()
    pane.destroy()

  # Propagate table with variables
  listVariables: ->
    variables = SettingsHelper.get 'variables'
    # TODO: Fix background message
    @variables.empty()

    if !variables || variables.length == 0
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

    cell = @find('#spark-ide-cloud-variables [data-id=' + variableName + '] td:eq(2)')
    cell.addClass 'loading'
    cell.text ''
    promise = spark.getVariable SettingsHelper.get('current_core'), variableName
    promise.done (e) =>
      cell.removeClass()
      if !!e.ok
        cell.addClass 'icon icon-issue-opened text-error'
        dfd.reject()
      else
        cell.text e.result
        dfd.resolve e.result
    , (e) =>
      cell.removeClass()
      cell.addClass 'icon icon-issue-opened text-error'
      dfd.reject()
    dfd.promise

  # Toggle watching variable
  toggleWatchVariable: (variableName) ->
    row = @find('#spark-ide-cloud-variables [data-id=' + variableName + ']')
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
            @subview 'parameters', new EditorView(mini: true, placeholderText: 'Parameters')
            @span ') == '
            @subview 'result', new EditorView(mini: true, placeholderText: 'Result')
            @span class: 'three-quarters inline-block hidden'
        row.find('button').on 'click', (event) =>
          @callFunction $(event.currentTarget).parent().attr('data-id')
        row.find('.editor:eq(0)').data('view').on 'core:confirm', (event) =>
          @callFunction $(event.currentTarget).parent().attr('data-id')
        row.find('.editor:eq(1)').data('view').hiddenInput.attr 'disabled', 'disabled'
        @functions.append row

  # Lock/unlock row
  setRowEnabled: (row, enabled) ->
    if enabled
      row.find('button').removeAttr 'disabled'
      row.find('.editor:eq(0)').data('view').hiddenInput.removeAttr 'disabled'
      row.find('.three-quarters').addClass 'hidden'
    else
      row.find('button').attr 'disabled', 'disabled'
      row.find('.editor:eq(0)').data('view').hiddenInput.attr 'disabled', 'disabled'
      row.find('.three-quarters').removeClass 'hidden'
      row.find('.editor:eq(1)').data('view').removeClass 'icon icon-issue-opened'

  # Call function via cloud
  callFunction: (functionName) ->
    dfd = whenjs.defer()
    row = @find('#spark-ide-cloud-functions [data-id=' + functionName + ']')
    @setRowEnabled row, false
    row.find('.editor:eq(1)').data('view').setText ' '
    params = row.find('.editor:eq(0)').data('view').getText()
    promise = spark.callFunction SettingsHelper.get('current_core'), functionName, params
    promise.done (e) =>
      @setRowEnabled row, true

      if !!e.ok
        row.find('.editor:eq(1)').data('view').addClass 'icon icon-issue-opened'
        dfd.reject()
      else
        row.find('.editor:eq(1)').data('view').setText e.return_value.toString()

        dfd.resolve e.return_value
    , (e) =>
      @setRowEnabled row, true
      row.find('.editor:eq(1)').data('view').addClass 'icon icon-issue-opened'

      dfd.reject()
    dfd.promise
