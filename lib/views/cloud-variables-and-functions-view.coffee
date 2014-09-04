{View, EditorView} = require 'atom'
$ = null
$$ = null
whenjs = require 'when'
SettingsHelper = null
ApiClient = null

module.exports =
class CloudVariablesAndFunctions extends View
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
    ApiClient = require '../vendor/ApiClient'

    @client = null

    @listVariables()
    @listFunctions()

    atom.workspaceView.command 'spark-ide:update-core-status', =>
      @listVariables()
      @listFunctions()

    atom.workspaceView.command 'spark-ide:logout', =>
      if @hasParent()
        @detach()

  serialize: ->

  destroy: ->
    @detach()

  toggle: ->
    if @hasParent()
      @detach()
    else
      atom.workspaceView.prependToBottom(this)

  listVariables: ->
    variables = SettingsHelper.get 'variables'

    @variables.empty()
    if variables.length == 0
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

        row.find('button').on 'click', (event) =>
          @refreshVariable $(event.target).parent().parent().attr('data-id')

        table.find('tbody').append row.find('tbody >')

      @variables.append table

      # Get initial values
      for variable in Object.keys(variables)
        @refreshVariable variable

  listFunctions: ->
    functions = SettingsHelper.get 'functions'

    @functions.empty()
    if functions.length == 0
      @functions.append $$ ->
        @ul class: 'background-message', =>
          @li 'No functions registered'
    else
      console.log functions
      for func in functions

        console.log func
        @functions.append $$ ->
          @div =>
            @button class: 'btn icon icon-zap', func
            @span '('
            @subview 'parameters', new EditorView(mini: true, placeholderText: 'Parameters')
            @span ') == '
            @subview 'result', new EditorView(mini: true, placeholderText: 'Result')

  refreshVariable: (variableName) ->
    dfd = whenjs.defer()
    @client ?= new ApiClient SettingsHelper.get('apiUrl'), SettingsHelper.get('access_token')

    cell = @find('#spark-ide-cloud-variables [data-id=' + variableName + '] td:eq(2)')
    cell.addClass 'loading'
    promise = @client.getVariable SettingsHelper.get('current_core'), variableName
    promise.done (e) =>
      if !!e.ok
        dfd.reject()
      else
        cell.removeClass 'loading'
        cell.text e.result
        dfd.resolve e.result
    dfd.promise
