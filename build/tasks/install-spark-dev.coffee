path = require 'path'
fs = require 'fs-extra'
request = require 'request'
Decompress = require 'decompress'
cp = require '../../script/utils/child-process-wrapper.js'
_s = require 'underscore.string'

workDir = null

module.exports = (grunt) ->
  {injectPackage, injectDependency} = require('./task-helpers')(grunt)

  grunt.registerTask 'install-spark-dev', 'Installs Particle Dev package', ->
    done = @async()
    workDir = grunt.config.get('workDir')
    particleDevPath = path.join(workDir, 'node_modules', 'spark-dev')
    particleDevVersion = grunt.config.get('particleDevVersion').replace('-dev', '')

    installDependencies = (done) ->
      # Build serialport
      packageJson = path.join(workDir, 'package.json')
      packages = JSON.parse(fs.readFileSync(packageJson))
      process.chdir(particleDevPath);
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

      verbose = if !grunt.option('verbose') then '' else ' --verbose'
      cp.safeExec command + ' install' + verbose, options, ->
        injectPackage 'spark-dev', particleDevVersion
        done()

    if _s.endsWith(particleDevVersion, '-dev')
      # Copy current sources
      fs.copySync path.join(__dirname, '..', '..'), particleDevPath
      installDependencies done
    else
      # Download the release
      tarballUrl = 'https://github.com/spark/spark-dev/archive/v' + particleDevVersion + '.tar.gz'
      tarballPath = path.join(workDir, 'sparkdev.tar.gz')

      r = request(tarballUrl)
      r.on 'end', ->
        decompress = new Decompress()
        decompress.src tarballPath
        decompress.dest particleDevPath
        decompress.use(Decompress.targz({ strip: 1 }))
        decompress.run (error) ->
          if error
            throw error

          fs.unlinkSync tarballPath
          fs.removeSync path.join(particleDevPath, 'build')
          fs.removeSync path.join(particleDevPath, 'docs')

          installDependencies done

      r.pipe(fs.createWriteStream(tarballPath))
