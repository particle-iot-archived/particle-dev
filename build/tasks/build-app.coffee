cp = require '../../script/utils/child-process-wrapper.js'
path = require 'path'
workDir = null

module.exports = (grunt) ->
  grunt.registerTask 'build-app', 'Builds executable', ->
    done = @async()

    process.chdir(grunt.config.get('workDir'))

    installDir = grunt.config.get('installDir')

    if !!process.env.TRAVIS
      tasks = 'set-version check-licenses lint generate-asar '
      tasks += 'mkdeb ' if process.platform is 'linux'
      tasks += 'create-windows-installer ' if process.platform is 'win32'
      tasks += 'codesign publish-build'
    else
      tasks = 'download-atom-shell download-atom-shell-chromedriver build set-version generate-asar '

      if not grunt.option('no-codesign')
        tasks += 'codesign '

      tasks += 'install'

    command = path.join('build', 'node_modules', '.bin', 'grunt') +
              ' --gruntfile ' + path.join('build', 'Gruntfile.coffee') +
              ' --install-dir "' + installDir + '" ' +
              tasks

    grunt.log.writeln '(i) Build command is ' + command

    cp.safeExec command, ->
      done()
