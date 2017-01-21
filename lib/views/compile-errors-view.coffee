{SelectView} = require 'particle-dev-views'
packageName = require '../utils/package-helper'

$$ = null
SettingsHelper = null
fs = null
path = null

module.exports =
class CompileErrorsView extends SelectView
  initialize: ->
    super

    {$$} = require 'atom-space-pen-views'

    @prop 'id', 'compile-errors-view'
    @addClass packageName()

  fixFilePath: (filename) ->
    splitFilename = filename.split path.sep
    path.join.apply this, splitFilename.slice(2)

  fixInoFile: (filename) ->
    fs ?= require 'fs-plus'
    path ?= require 'path'
    # this logic is borken...can't always assume we can infer the path
    # if the file exist locally, assume it's good
    # the view shouldn't be fixing up the filename paths...;-)
    if fs.existsSync(filename)
      return filename

    rootPath = atom.project.getPaths()[0]
    files = fs.listTreeSync rootPath
    for file in files
      if file.replace(rootPath + path.sep, '') == filename
        return file.slice(rootPath.length + 1)
    return filename.replace '.cpp', '.ino'

  show: =>
    SettingsHelper ?= require '../utils/settings-helper'

    compileStatus = SettingsHelper.getLocal 'compile-status'
    if compileStatus?.errors
      @setItems compileStatus.errors
    else
      @setLoading 'There were no compile errors'
    super



  viewForItem: (item) ->
    self = @
    $$ ->
      @li class: 'two-lines', =>
        @div class: 'primary-line', item.text
        @div class: 'secondary-line', self.fixInoFile(item.filename) +
                                      ":#{item.line}:#{item.column}"

  confirmed: (item) ->
    filename = @fixInoFile item.filename

    # Open file with error in editor
    opening = atom.workspace.open filename, { searchAllPanes: true }
    opening.done (editor) ->
      editor.setCursorBufferPosition [item.line-1, item.column-1],
    @hide()

  getFilterKey: ->
    'message'
