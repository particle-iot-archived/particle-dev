cp = require '../../script/utils/child-process-wrapper.js'
path = require 'path'
workDir = null

module.exports = (grunt) ->
  grunt.registerTask 'package-app', 'Packages app', ->
    done = @async()

    process.chdir(path.join(__dirname, '..'))
    installDir = grunt.config.get('installDir')

    if process.platform is 'darwin'
      command = 'ditto -ck --rsrc --sequesterRsrc --keepParent ' +
                '"' + installDir + '" ' +
                '"' + path.dirname(installDir) + 'spark-dev-mac.zip"'
      console.log command
      cp.safeExec command, ->
        done()

    else if process.platform is 'win32'
      outFile = path.join(path.dirname(installDir), 'spark-dev-windows.exe')
      installerFile = path.join('resources', 'installer.nsi')
      command = 'makensis /DSOURCE="' + installDir +
                  '" /DOUT_FILE="' + outFile + '" ' +
                  installerFile
      console.log command
      cp.safeExec command, ->
        done()
