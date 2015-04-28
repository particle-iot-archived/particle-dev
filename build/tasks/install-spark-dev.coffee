path = require 'path'
fs = require 'fs-extra'
request = require 'request'
Decompress = require 'decompress'
cp = require '../../script/utils/child-process-wrapper.js'

workDir = null

module.exports = (grunt) ->
  grunt.registerTask 'install-spark-dev', 'Installs Spark Dev package', ->
    done = @async()
    workDir = grunt.config.get('workDir')

    tarballUrl = 'https://github.com/spark/spark-dev/archive/v' + grunt.config.get('sparkDevVersion') + '.tar.gz'
    tarballPath = path.join(workDir, 'sparkdev.tar.gz')
    sparkDevPath = path.join(workDir, 'node_modules', 'spark-dev')
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

        # Build serialport
        packageJson = path.join(workDir, 'package.json')
        packages = JSON.parse(fs.readFileSync(packageJson))
        packages.version = grunt.config.get('sparkDevVersion')
        process.chdir(sparkDevPath);
        env = process.env
        env['ATOM_NODE_VERSION'] = packages.atomShellVersion
        env['ATOM_HOME'] = if process.platform is 'win32' then process.env.USERPROFILE else process.env.HOME
        options = {
          env: env
        }

        if process.platform == 'win32'
          command = '..\\..\\apm\\node_modules\\atom-package-manager\\bin\\apm.cmd'
        else
          command = '../../apm/node_modules/atom-package-manager/bin/apm'

        verbose = if !grunt.option('verbose') '' else ' --verbose'
        cp.safeExec command + ' install' + verbose, options, ->
          packages.packageDependencies['spark-dev'] = grunt.config.get('sparkDevVersion')
          fs.writeFileSync(packageJson, JSON.stringify(packages, null, '  '))
          done()

    r.pipe(fs.createWriteStream(tarballPath))
