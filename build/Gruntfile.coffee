temp = require 'temp'
path = require 'path'
fs = require 'fs'

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

  appName = 'Spark Dev'
  installDir = path.join(__dirname, '..', 'dist', process.platform, appName)
  if process.platform is 'darwin'
    installDir += '.app'

  # Get Atom Version from .atomrc
  atomrc = fs.readFileSync(path.join(__dirname, '..', '.atomrc')).toString()
  lines = atomrc.split "\n"
  atomVersion = null
  for line in lines
    [key, value] = line.split '='
    if key.indexOf('ATOM_VERSION') > 0
      atomVersion = value

  # TODO: Get Spark Dev version from options/latest tag

  grunt.initConfig
    workDir: workDir
    atomVersion: atomVersion
    sparkDevVersion: '0.0.18'
    appName: appName
    installDir: installDir

  tasks = []

  console.log grunt.config.get('atomVersion')
  return

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
