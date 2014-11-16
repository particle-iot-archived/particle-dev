fs = require 'fs-extra'
path = require 'path'
spawnSync = require('child_process').spawnSync || require('spawn-sync')
workDir = null

pathFile = (patchFile, targetFile) ->
  patchFile = path.join(__dirname, 'patches', patchFile)
  targetFile = path.join(workDir, targetFile.replace('/', path.sep))

  result = spawnSync 'patch', [targetFile, '<', patchFile]
  if result.status != 0
    process.stderr.write result.stderr
    process.exit result.status

module.exports = (grunt) ->
  grunt.registerTask 'patch-code', 'Patches Atom code', ->
    workDir = grunt.config.get('workDir')

    pathFile 'atom-application.patch', 'src/browser/atom-application.coffee'
    pathFile 'npmrc.patch', '.npmrc'
    pathFile 'atom.patch', 'src/atom.coffee'
    pathFile 'auto-update-manager.patch', 'src/browser/auto-update-manager.coffee'
    pathFile 'atom-window.patch', 'src/browser/atom-window.coffee'
    pathFile 'workspace.patch', 'src/workspace.coffee'
    pathFile 'settings-view.patch', 'node_modules/settings-view/lib/settings-view.coffee'
    pathFile 'reporter.patch', 'node_modules/exception-reporting/lib/reporter.coffee'

    if process.platform is 'darwin'
      pathFile 'atom-Info.patch', 'resources/mac/atom-Info.plist'
      pathFile 'codesign-task.patch', 'build/tasks/codesign-task.coffee'
      pathFile 'darwin.patch', 'menus/darwin.cson'
    else if process.platform is 'win32'
      pathFile 'win32.patch', 'menus/win32.cson'
    else
      pathFile 'linux.patch', 'menus/linux.cson'
