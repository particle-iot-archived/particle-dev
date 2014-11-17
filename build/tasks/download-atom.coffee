path = require 'path'
fs = require 'fs'
request = require 'request'
Decompress = require 'decompress'

workDir = null

module.exports = (grunt) ->
  grunt.registerTask 'download-atom', 'Downloads Atom into working dir', ->
    done = @async()
    workDir = grunt.config.get('workDir')

    tarballUrl = 'https://github.com/atom/atom/archive/' + grunt.config.get('atomVersion') + '.tar.gz'
    tarballPath = path.join(grunt.config.get('workDir'), 'atom.tar.gz')
    r = request(tarballUrl)
    r.on 'end', ->
      decompress = new Decompress()
      decompress.src tarballPath
      decompress.dest workDir
      decompress.use(Decompress.targz({ strip: 1 }))
      decompress.run (error) ->
        if error
          throw error

        fs.chmodSync path.join(workDir, 'script', 'set-version'), '755'

        fs.unlinkSync tarballPath
        done()

    r.pipe(fs.createWriteStream(tarballPath))
