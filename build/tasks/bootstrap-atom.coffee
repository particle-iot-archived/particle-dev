cp = require '../../script/utils/child-process-wrapper.js'
workDir = null

module.exports = (grunt) ->
  grunt.registerTask 'bootstrap-atom', 'Bootstraps Atom', ->
    done = @async()

    process.chdir(grunt.config.get('workDir'))

    cp.safeSpawn 'node', ['script/bootstrap'], ->
      done()
