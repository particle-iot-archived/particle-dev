cp = require '../../script/utils/child-process-wrapper.js'
path = require 'path'
whenjs = require 'when'
sequence = require 'when/sequence'
workDir = null
_grunt = null

runAtomTask = (task, cb) ->
  dfd = whenjs.defer()
  buildDir = _grunt.config.get('buildDir')
  command = path.join('build', 'node_modules', '.bin', 'grunt') +
            ' --gruntfile ' + path.join('build', 'Gruntfile.coffee') +
            ' --build-dir "' + buildDir + '" ' + task

  cp.safeExec command, (result) ->
    if !!result
      dfd.reject result
      _grunt.fail.fatal result
    else
      dfd.resolve result

  dfd.promise

module.exports = (grunt) ->
  _grunt = grunt
  grunt.registerTask 'build-app', 'Builds executable', ->
    done = @async()

    process.chdir(grunt.config.get('workDir'))

    tasks = [
      'download-atom-shell',
      'download-atom-shell-chromedriver',
      'build',
      'set-version',
      'check-licenses',
      'lint',
      'generate-asar'
    ]

    tasks.push('mkdeb') if process.platform is 'linux'
    tasks.push('create-windows-installer') if process.platform is 'win32'
    tasks.push('codesign', 'publish-build')
    sequence(runAtomTask.bind(this, task) for task in tasks).done ->
      done()
