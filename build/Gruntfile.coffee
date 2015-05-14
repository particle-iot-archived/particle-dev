temp = require 'temp'
path = require 'path'
fs = require 'fs'
_s = require 'underscore.string'

module.exports = (grunt) ->
  grunt.loadTasks('tasks')

  if !!grunt.option('workDir')
    workDir = grunt.option('workDir')
  else
    # temp.track()
    if process.platform is 'win32'
      affixes =
        prefix: 'spark-dev'
        suffix: ''
        dir: process.cwd().split(path.sep)[0]
      workDir = temp.mkdirSync affixes
    else
      workDir = temp.mkdirSync 'spark-dev'

  grunt.log.writeln '(i) Work dir is ' + workDir

  if grunt.option('showWorkDir')
    cp = require 'child_process'
    cp.exec 'open ' + workDir

  appName = 'Particle Dev'
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
      atomVersion = _s.trim(value)
  grunt.log.writeln '(i) Atom version is ' + atomVersion

  # Get Spark Dev version from options/latest tag
  if !!grunt.option('particleDevVersion')
    particleDevVersion = grunt.option('particleDevVersion')
  else
    request = require 'sync-request'
    response = request 'get', 'https://api.github.com/repos/spark/spark-dev/releases',
      headers:
        'User-Agent': 'Particle Dev build script'

    releases = JSON.parse response.getBody()
    particleDevVersion = releases[0].tag_name.substring(1)
  grunt.log.writeln '(i) Particle Dev version is ' + particleDevVersion

  grunt.initConfig
    workDir: workDir
    atomVersion: atomVersion
    particleDevVersion: particleDevVersion
    appName: appName
    installDir: installDir

  tasks = []

  if !grunt.option('workDir')
    tasks = tasks.concat [
      'download-atom',
      'inject-packages',
      'install-unpublished-packages',
      'bootstrap-atom',
      'copy-resources',
      'install-spark-dev',
    ]

  tasks = tasks.concat [
    'patch-code',
    'build-app',
    'package-app'
  ]

  grunt.registerTask('default', tasks)
