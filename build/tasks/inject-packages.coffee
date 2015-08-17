path = require 'path'
fs = require 'fs-extra'
workDir = null

module.exports = (grunt) ->
  {injectPackage, injectDependency} = require('./task-helpers')(grunt)

  grunt.registerTask 'inject-packages', 'Inject packages into packages.json and node_modules dir', ->
    workDir = grunt.config.get 'workDir'

    injectPackage 'file-type-icons', '0.7.1'
    injectPackage 'switch-header-source', '0.20.0'
    injectPackage 'resize-panes', '0.2.0'
    injectPackage 'maximize-panes', '0.2.0'
    injectPackage 'move-panes', '0.2.0'
    injectPackage 'swap-panes', '0.2.0'
    injectPackage 'tool-bar', '0.1.8'
    injectPackage 'tool-bar-main', '0.0.8'
    injectPackage 'monokai', '0.18.0'

    injectPackage 'particle-dev-release-notes', '0.53.2'
    injectPackage 'language-particle', '0.3.4'
    injectPackage 'particle-dev-exception-reporting', '0.36.1'
    injectPackage 'particle-dev-cloud-functions', '0.0.9'
    injectPackage 'particle-dev-cloud-variables', '0.0.8'

    # Disable folowing packages:
    # injectPackage 'welcome'
    injectPackage 'feedback'
    injectPackage 'metrics'
    injectPackage 'deprecation-cop'

    injectDependency 'coffeestack', 'git+https://github.com/spark/coffeestack.git#master'
