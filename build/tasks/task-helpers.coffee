path = require 'path'
fs = require 'fs-extra'

module.exports = (grunt) ->
  injectPackage: (name, version=null) ->
    packageJson = path.join(grunt.config.get('workDir'), 'package.json')
    packages = JSON.parse(fs.readFileSync(packageJson))
    if !version
      delete packages.packageDependencies[name]
    else
      packages.packageDependencies[name] = version
    fs.writeFileSync(packageJson, JSON.stringify(packages, null, '  '))
