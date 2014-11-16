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
                '"' + installDir + '.zip"'
      cp.safeExec command, ->
        done()

    else if process.platform is 'win32'
      cleanName = grunt.config.get('appName').replace(' ', '')
      outFile = path.join(path.dirname(installDir), 'Install' + cleanName + '.exe')
      installerFile = path.join('resources', 'installer.nsi')
      command = 'makensis /DSOURCE="' + installDir +
                  '" /DOUT_FILE="' + outFile + '" ' +
                  installerFile
      console.log command
      cp.safeExec command, ->
        done()
