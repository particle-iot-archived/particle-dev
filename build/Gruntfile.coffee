temp = require 'temp'

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

  tasks = []

  if !grunt.option('workDir')
    tasks = tasks.concat [
      'download-atom',
      'inject-packages',
      'bootstrap-atom',
      'copy-resources',
      'install-spark-dev',
      'install-unpublished-packages',
    ]

  tasks = tasks.concat [
    'patch-code',
    # 'set-app-version',
    # 'build-app',
    # 'package-app'
  ]

  grunt.registerTask('default', tasks)
