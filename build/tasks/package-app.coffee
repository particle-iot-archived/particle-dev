cp = require '../../script/utils/child-process-wrapper.js'
path = require 'path'
fs = require 'fs-extra'
workDir = null

module.exports = (grunt) ->
  grunt.registerTask 'package-app', 'Packages app', ->
    done = @async()

    process.chdir(path.join(__dirname, '..'))
    installDir = grunt.config.get('installDir')
    particleDevVersion = grunt.config.get('particleDevVersion')
    outDir = path.join(path.dirname(installDir), 'out')
    fs.mkdirSync outDir

    if process.platform is 'darwin'
      command = 'ditto -ck --rsrc --sequesterRsrc --keepParent ' +
                '"' + installDir + '" ' +
                '"' + outDir + path.sep +
                'particle-dev-mac-' + particleDevVersion + '.zip"'
      console.log command
      cp.safeExec command, ->
        done()

    else if process.platform is 'win32'
      outFilename = 'particle-dev-windows-' + particleDevVersion + '.exe'
      outFile = path.join(outDir, outFilename)
      installerFile = path.join('resources', 'installer.nsi')
      command = 'makensis /DSOURCE="' + installDir +
                  '" /DOUT_FILE="' + outFile + '" ' +
                  installerFile
      console.log command
      cp.safeExec command, ->
        done()
