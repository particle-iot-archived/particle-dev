path = require 'path'
fs = require 'fs-extra'
workDir = null

module.exports = (grunt) ->
  {injectPackage, injectDependency} = require('./task-helpers')(grunt)

  grunt.registerTask 'inject-packages', 'Inject packages into packages.json and node_modules dir', ->
    workDir = grunt.config.get 'workDir'

    injectPackage 'file-type-icons', '0.6.0'
    injectPackage 'switch-header-source', '0.19.0'
    injectPackage 'resize-panes', '0.1.0'
    injectPackage 'maximize-panes', '0.1.0'
    injectPackage 'move-panes', '0.1.2'
    injectPackage 'swap-panes', '0.1.0'
    injectPackage 'tool-bar', '0.1.7'
    injectPackage 'tool-bar-main', '0.0.8'
    injectPackage 'monokai', '0.14.0'
    injectPackage 'welcome'
    injectPackage 'feedback'
    injectPackage 'release-notes'
    injectPackage 'exception-reporting'
    injectPackage 'metrics'
    injectPackage 'deprecation-cop'

    injectDependency 'coffeestack', 'git+https://github.com/spark/coffeestack.git#master'
