fs = require 'fs-extra'
path = require 'path'
cp = require 'child_process'
workDir = null

pathFile = (patchFile, targetFile, callback) ->
  console.log ' Applying ' + patchFile
  patchFile = path.join(__dirname, 'patches', patchFile)
  targetFile = path.join(workDir, targetFile.replace('/', path.sep))

  command = 'patch -i ' + patchFile + ' ' + targetFile
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

    # Remove broken spec
    fs.removeSync path.join(workDir, 'node_modules', 'coffeestack', 'spec')
    fs.removeSync path.join(workDir, 'node_modules', 'exception-reporting', 'node_modules', 'coffeestack', 'spec')

    # Patching
    pathFile 'atom-application.patch', 'src/browser/atom-application.coffee', ->
      pathFile 'atom.patch', 'src/atom.coffee', ->
        pathFile 'main.patch', 'src/browser/main.coffee', ->
          pathFile 'auto-update-manager.patch', 'src/browser/auto-update-manager.coffee', ->
            pathFile 'atom-window.patch', 'src/browser/atom-window.coffee', ->
              pathFile 'workspace.patch', 'src/workspace.coffee', ->
                pathFile 'Gruntfile.patch', 'build/Gruntfile.coffee', ->
                  pathFile 'package-manager.patch', 'node_modules/settings-view/lib/package-manager.coffee', ->
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
