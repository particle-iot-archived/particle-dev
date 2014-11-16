temp = require 'temp'
path = require 'path'

module.exports = (grunt) ->
  grunt.loadTasks('tasks')

  if !!grunt.option('workDir')
    workDir = grunt.option('workDir')
  else
    # temp.track()
    workDir = temp.mkdirSync 'spark-dev'

  grunt.log.writeln 'Work dir is ' + workDir

  if grunt.option('showWorkDir')
    cp = require 'child_process'
    cp.exec 'open ' + workDir

  grunt.initConfig
    workDir: workDir
    atomVersion: 'v0.140.0'
    sparkDevVersion: '0.0.17'
    appName: 'Spark Dev'
    installDir: path.join(__dirname, '..', 'dist', process.platform)

  tasks = []

  if !grunt.option('workDir')
    tasks = tasks.concat [
      'download-atom',
      'inject-packages',
      'bootstrap-atom',
      'copy-resources',
      'install-spark-dev',
      'install-unpublished-packages',
      'patch-code',
      'build-app',
    ]

  tasks = tasks.concat [
    'package-app'
  ]

  grunt.registerTask('default', tasks)
