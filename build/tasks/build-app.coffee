cp = require '../../script/utils/child-process-wrapper.js'
path = require 'path'
workDir = null

module.exports = (grunt) ->
  grunt.registerTask 'build-app', 'Builds executable', ->
    done = @async()

    process.chdir(grunt.config.get('workDir'))

    installDir = path.join(grunt.config.get('installDir'), grunt.config.get('appName'))
    if process.platform is 'darwin'
      installDir += '.app'

    command = 'build/node_modules/.bin/grunt ' +
              '--gruntfile build/Gruntfile.coffee ' +
              '--install-dir "' + installDir + '" ' +
              'download-atom-shell build set-version codesign install'
    cp.safeExec command, ->
      done()
