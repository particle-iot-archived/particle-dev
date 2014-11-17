cp = require '../../script/utils/child-process-wrapper.js'
path = require 'path'
workDir = null

module.exports = (grunt) ->
  grunt.registerTask 'build-app', 'Builds executable', ->
    done = @async()

    process.chdir(grunt.config.get('workDir'))

    installDir = grunt.config.get('installDir')

    command = path.join('build', 'node_modules', '.bin', 'grunt') +
              ' --gruntfile ' + path.join('build', 'Gruntfile.coffee') +
              ' --install-dir "' + installDir + '" ' +
              'download-atom-shell build set-version '

    if not grunt.config.get('no-codesign')
      command += 'codesign '

    command += 'install'

    cp.safeExec command, ->
      done()
