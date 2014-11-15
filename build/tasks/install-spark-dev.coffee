path = require 'path'
fs = require 'fs-extra'
request = require 'request'
Decompress = require 'decompress'
workDir = null

module.exports = (grunt) ->
  grunt.registerTask 'install-spark-dev', 'Installs Spark Dev package', ->
    done = @async()

    tarballUrl = 'https://github.com/spark/spark-dev/archive/' + grunt.config.get('sparkDevVersion') + '.tar.gz'
    tarballPath = path.join(grunt.config.get('workDir'), 'sparkdev.tar.gz')
    sparkDevPath = path.join(grunt.config.get('workDir'), 'node_modules', 'spark-dev')
    r = request(tarballUrl)
    r.on 'end', ->
      decompress = new Decompress()
      decompress.src tarballPath
      decompress.dest sparkDevPath
      decompress.use(Decompress.targz({ strip: 1 }))
      decompress.run (error) ->
        if error
          throw error

        fs.unlinkSync tarballPath
        fs.removeSync path.join(sparkDevPath, 'build')
        fs.removeSync path.join(sparkDevPath, 'docs')

        # TODO: Build serialport
        done()

    r.pipe(fs.createWriteStream(tarballPath))
