path = require 'path'
fs = require 'fs-extra'
request = require 'request'
Decompress = require 'decompress'
cp = require '../../script/utils/child-process-wrapper.js'
injectPackage = null
workDir = null

installPackage = (owner, name, version, callback) ->
  tarballUrl = "https://github.com/#{owner}/#{name}/archive/master.tar.gz"
  tarballPath = path.join(workDir, 'name.tar.gz')
  r = request(tarballUrl)
  r.on 'end', ->
    destination = path.join(workDir, 'node_modules', name)
    decompress = new Decompress()
    decompress.src tarballPath
    decompress.dest destination
    decompress.use(Decompress.targz({ strip: 1 }))
    decompress.run (error) ->
      if error
        console.log 'Error while decompressing archive:', error
        throw error

      fs.unlinkSync tarballPath
      injectPackage name, version

      # set readme field
      packageJson = path.join(destination, 'package.json')
      packages = JSON.parse(fs.readFileSync(packageJson))
      packages.readme = 'ERROR: No README data found!'
      fs.writeFileSync(packageJson, JSON.stringify(packages, null, '  '))

      options =
        cwd: path.join(workDir, 'node_modules', name)
      cp.safeExec 'npm install', options, ->
        callback()
  r.on 'error', (err) ->
    console.log 'Error while fetching package:', err

  r.pipe(fs.createWriteStream(tarballPath))

module.exports = (grunt) ->
  {injectPackage} = require('./task-helpers')(grunt)

  grunt.registerTask 'install-unpublished-packages', 'Installs unpublished packages', ->
    workDir = grunt.config.get 'workDir'
    done = @async()

    # installPackage 'spark', 'welcome-spark', '0.27.0', ->
    installPackage 'spark', 'particle-dev-release-notes', '0.53.0', ->
      installPackage 'spark', 'language-spark', '0.3.1', ->
        installPackage 'spark', 'exception-reporting', '0.36.0', ->
          installPackage 'spark', 'spark-dev-cloud-functions', '0.0.5', ->
            installPackage 'spark', 'particle-dev-cloud-variables', '0.0.4', ->
              installPackage 'spark', 'metrics', '0.45.0', ->
                done()
