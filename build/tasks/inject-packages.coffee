path = require 'path'
fs = require 'fs-extra'
workDir = null

module.exports = (grunt) ->
  {injectPackage} = require('./task-helpers')(grunt)

  grunt.registerTask 'inject-packages', 'Inject packages into packages.json and node_modules dir', ->
    workDir = grunt.config.get 'workDir'

    injectPackage 'file-type-icons', '0.4.4'
    injectPackage 'switch-header-source', '0.8.0'
    injectPackage 'resize-panes', '0.1.0'
    injectPackage 'maximize-panes', '0.1.0'
    injectPackage 'move-panes', '0.1.2'
    injectPackage 'swap-panes', '0.1.0'
    injectPackage 'toolbar', '0.0.9'
    injectPackage 'monokai', '0.8.0'
    injectPackage 'welcome'
    injectPackage 'feedback'
    injectPackage 'release-notes'
    injectPackage 'symbols-view'
    injectPackage 'exception-reporting'
