cp = require '../../script/utils/child-process-wrapper.js'
path = require 'path'
whenjs = require 'when'
sequence = require 'when/sequence'
workDir = null
_grunt = null

module.exports = (grunt) ->
  _grunt = grunt
  grunt.registerTask 'build-app', 'Builds executable', ->
    workDir = grunt.config.get('workDir')
    grunt.option('build-dir', grunt.config.get('buildDir'))

    # Register Atom's tasks
    process.chdir path.join(workDir, 'build')
    grunt.loadTasks 'Gruntfile.coffee'
    grunt.loadTasks '.'

    tasks = [
      'download-atom-shell',
      'download-atom-shell-chromedriver',
      'build',
      'set-version',
      'check-licenses',
      'lint',
      'generate-asar'
    ]

    if process.platform is 'win32'
      tasks.push('codesign:exe')
      tasks.push('create-windows-installer:installer')
      tasks.push('codesign:installer')
    tasks.push('codesign:app') if process.platform is 'darwin'
    tasks.push('mkdeb') if process.platform is 'linux'
    tasks.push('publish-build')
    grunt.task.run(tasks)
