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
              'download-atom-shell download-atom-shell-chromedriver build set-version generate-asar '

    if not grunt.option('no-codesign')
      command += 'codesign '

    command += 'install'

    grunt.log.writeln '(i) Build command is ' + command

    cp.safeExec command, ->
      done()
