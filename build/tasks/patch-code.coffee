fs = require 'fs-extra'
path = require 'path'
cp = require 'child_process'
workDir = null

pathFile = (patchFile, targetFile, callback) ->
  console.log 'Applying ' + patchFile
  patchFile = path.join(__dirname, 'patches', patchFile)
  targetFile = path.join(workDir, targetFile.replace('/', path.sep))

  command = 'patch -i ' + patchFile + ' ' + targetFile
  console.log command
  result = cp.exec command, (error, stdout, stderr) ->
    if error
      process.stderr.write error
      process.exit error.code
    else
      callback()

module.exports = (grunt) ->
  grunt.registerTask 'patch-code', 'Patches Atom code', ->
    workDir = grunt.config.get('workDir')
    done = @async()

    pathFile 'atom-application.patch', 'src/browser/atom-application.coffee', ->
      pathFile 'npmrc.patch', '.npmrc', ->
        pathFile 'atom.patch', 'src/atom.coffee', ->
          pathFile 'auto-update-manager.patch', 'src/browser/auto-update-manager.coffee', ->
            pathFile 'codesign-task.patch', 'build/tasks/codesign-task.coffee', ->
              pathFile 'atom-window.patch', 'src/browser/atom-window.coffee', ->
                pathFile 'workspace.patch', 'src/workspace.coffee', ->
                  pathFile 'settings-view.patch', 'node_modules/settings-view/lib/settings-view.coffee', ->
                   pathFile 'reporter.patch', 'node_modules/exception-reporting/lib/reporter.coffee', ->
                    if process.platform is 'darwin'
                      pathFile 'atom-Info.patch', 'resources/mac/atom-Info.plist', ->
                        pathFile 'codesign-task.patch', 'build/tasks/codesign-task.coffee', ->
                          pathFile 'darwin.patch', 'menus/darwin.cson', ->
                            done()
                    else if process.platform is 'win32'
                      pathFile 'win32.patch', 'menus/win32.cson', ->
                        done()
                    else
                      pathFile 'linux.patch', 'menus/linux.cson', ->
                        done()
