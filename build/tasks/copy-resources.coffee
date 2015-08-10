path = require 'path'
fs = require 'fs-extra'
workDir = null

copyResource = (from, to) ->
  to = to.replace '/', path.sep
  fs.copySync path.join(__dirname, '..', 'resources', from),
              path.join(workDir, to)

module.exports = (grunt) ->
  grunt.registerTask 'copy-resources', 'Copies resources', ->
    workDir = grunt.config.get 'workDir'

    copyResource 'atom.png', 'resources/atom.png'
    copyResource 'config.cson', 'dot-atom/config.cson'

    if process.platform is 'darwin'
      copyResource 'particle-dev.icns', 'resources/mac/atom.icns'
    else if process.platform is 'win32'
      copyResource 'particle-dev.ico', 'resources/win/atom.ico'
