{SelectView} = require 'spark-dev-views'

$$ = null
SerialHelper = null
SettingsHelper = null
fs = null
path = null

module.exports =
class CompileErrorsView extends SelectView
  initialize: ->
    super

    {$$} = require 'atom-space-pen-views'
    {CompositeDisposable} = require 'atom'

    @prop 'id', 'spark-dev-compile-errors-view'

  @fixFilePath: (filename) ->
    splitFilename = filename.split path.sep
    path.join.apply this, splitFilename.slice(2)

  # Parse gcc errors into array
  @parseErrors: (raw) ->
    path ?= require 'path'

    lines = raw.split "\n"
    errors = []
    for line in lines
      result = line.match /^([^:]+):(\d+):(\d+):\s(\w+\s*\w*):(.*)$/
      if result and result[4].indexOf('error') > -1
        errors.push {
          file: @fixFilePath(result[1]),
          row: result[2],
          col: result[3],
          type: result[4],
          message: result[5]
        }
      else
        result = line.match /^([^:]+):(\d+):\s(.*)$/
        if result
          # This is probably "undefined" error
          errors.push {
            file: path.basename(@fixFilePath(result[1])),
            row: result[2],
            col: 0,
            type: 'error',
            message: result[3]
          }
    errors

  show: =>
    SettingsHelper ?= require '../utils/settings-helper'

    compileStatus = SettingsHelper.getLocal 'compile-status'
    if compileStatus?.errors
      @setItems compileStatus.errors
    else
      @setLoading 'There were no compile errors'
    super

  fixInoFile: (filename) ->
    fs ?= require 'fs-plus'
    path ?= require 'path'

    rootPath = atom.project.getPaths()[0]
    files = fs.listTreeSync rootPath
    for file in files
      if file.replace(rootPath + path.sep, '') == filename
        return file.slice(rootPath.length + 1)
    return filename.replace '.cpp', '.ino'

  viewForItem: (item) ->
    self = @
    $$ ->
      @li class: 'two-lines', =>
        @div class: 'primary-line', item.message
        @div class: 'secondary-line', self.fixInoFile(item.file) + ':' + item.row + ':' + item.col

  confirmed: (item) ->
    filename = @fixInoFile item.file

    # Open file with error in editor
    opening = atom.workspace.open filename, { searchAllPanes: true }
    opening.done (editor) =>
      editor.setCursorBufferPosition [item.row-1, item.col-1],
    @hide()

  getFilterKey: ->
    'message'
