path = require 'path'
fs = require 'fs-extra'
request = require 'request'
Decompress = require 'decompress'
injectPackage = null
workDir = null

installPackage = (owner, name, version, callback) ->
  tarballUrl = 'https://github.com/' + owner + '/' + name + '/archive/master.tar.gz'
  tarballPath = path.join(workDir, 'name.tar.gz')
  r = request(tarballUrl)
  r.on 'end', ->
    decompress = new Decompress()
    decompress.src tarballPath
    decompress.dest path.join(workDir, 'node_modules', name)
    decompress.use(Decompress.targz({ strip: 1 }))
    decompress.run (error) ->
      if error
        throw error

      fs.unlinkSync tarballPath
      injectPackage name, version
      callback()

  r.pipe(fs.createWriteStream(tarballPath))

module.exports = (grunt) ->
  {injectPackage} = require('./task-helpers')(grunt)

  grunt.registerTask 'install-unpublished-packages', 'Installs unpublished packages', ->
    workDir = grunt.config.get 'workDir'
    done = @async()

    installPackage 'spark', 'welcome-spark', '0.19.0', ->
      installPackage 'spark', 'feedback-spark', '0.34.0', ->
        installPackage 'spark', 'release-notes-spark', '0.36.0', ->
          installPackage 'spark', 'language-spark', '0.3.0', ->
            done()
