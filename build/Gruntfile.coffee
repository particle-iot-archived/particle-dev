path = require 'path'
fs = require 'fs-extra'
_s = require 'underscore.string'

module.exports = (grunt) ->
  grunt.loadTasks('tasks')

  appName = 'Particle Dev'
  if process.platform == 'win32'
    root = process.cwd().split(path.sep)[0]
    workDir = path.join(root, 'atom-work-dir')
    buildDir = path.join(root, 'particle-dev-' + process.platform)
  else
    workDir = path.join(__dirname, '..', 'dist', 'atom-work-dir')
    buildDir = path.join(__dirname, '..', 'dist', process.platform)

  if fs.existsSync(workDir) && !grunt.option('keepAtomWorkDir')
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
  else if !!process.env.TRAVIS_TAG or !!process.env.APPVEYOR_REPO_TAG_NAME
    tag = process.env.TRAVIS_TAG ? process.env.APPVEYOR_REPO_TAG_NAME
    # Drop the "v" from tag name
    particleDevVersion = tag.slice(1)
  else
    packageJson = path.join(__dirname, '..', 'package.json')
    packageObject = JSON.parse(fs.readFileSync(packageJson))
    particleDevVersion = packageObject.version + '-' + process.env.JANKY_SHA1
  grunt.log.writeln '(i) Particle Dev version is ' + particleDevVersion

  grunt.initConfig
    workDir: workDir
    atomVersion: atomVersion
    particleDevVersion: particleDevVersion
    appName: appName
    buildDir: buildDir

  tasks = []

  grunt.registerTask 'sleep', 'Sleeps for a moment', ->
    done = @async()
    setTimeout ->
      done()
    , 1000 * 60 # Minute

  if !grunt.option('keepAtomWorkDir')
    tasks = tasks.concat [
      'download-atom',
      'sleep',
      'patch-atom-version',
      'inject-packages',
      'bootstrap-atom',
      'copy-resources',
      'install-particle-dev',
      'patch-code',
    ]

  tasks = tasks.concat [
    'build-app',
  ]

  grunt.registerTask('default', tasks)
