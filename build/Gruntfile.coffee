path = require 'path'
fs = require 'fs-extra'
_s = require 'underscore.string'

module.exports = (grunt) ->
  grunt.loadTasks('tasks')

  appName = 'Particle Dev'
  workDir = path.join(__dirname, '..', 'dist', 'atom-work-dir')
  buildDir = path.join(__dirname, '..', 'dist', process.platform)


  if fs.existsSync(workDir) && !!grunt.option('keepAtomWorkDir')
    fs.removeSync(workDir)
  fs.ensureDirSync(workDir)

  # Get Atom Version from .atomrc
  atomrc = fs.readFileSync(path.join(__dirname, '..', '.atomrc')).toString()
  lines = atomrc.split "\n"
  atomVersion = null
  for line in lines
    [key, value] = line.split '='
    if key.indexOf('ATOM_VERSION') > 0
      atomVersion = _s.trim(value)
  grunt.log.writeln '(i) Atom version is ' + atomVersion

  # Get Particle Dev version from options/current sources
  if !!grunt.option('particleDevVersion')
    particleDevVersion = grunt.option('particleDevVersion')
  else if !!process.env.TRAVIS_TAG
    # Drop the "v" from tag name
    particleDevVersion = process.env.TRAVIS_TAG.slice(1)
  else
    packageJson = path.join(__dirname, '..', 'package.json')
    packageObject = JSON.parse(fs.readFileSync(packageJson))
    particleDevVersion = packageObject.version + '-dev'
  grunt.log.writeln '(i) Particle Dev version is ' + particleDevVersion

  grunt.initConfig
    workDir: workDir
    atomVersion: atomVersion
    particleDevVersion: particleDevVersion
    appName: appName
    buildDir: buildDir

  tasks = []

  if !grunt.option('keepAtomWorkDir')
    tasks = tasks.concat [
      'download-atom',
      'patch-atom-version',
      'inject-packages',
      'install-unpublished-packages',
      'bootstrap-atom',
      'copy-resources',
      'install-spark-dev',
      'patch-code',
    ]

  tasks = tasks.concat [
    'build-app',
  ]

  grunt.registerTask('default', tasks)
