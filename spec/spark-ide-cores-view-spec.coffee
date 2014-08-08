{WorkspaceView} = require 'atom'
$ = require('atom').$
settings = null

describe 'Select Core View Tests', ->
  activationPromise = null
  coresView = null
  originalProfile = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
        coresView = mainModule.coresView

    settings = require '../lib/settings'
    originalProfile = settings.profile
    # For tests not to mess up our profile, we have to switch to test one...
    settings.switchProfile('spark-ide-test')
    # ...but Node.js cache won't allow loading settings.js again so
    # we have to clear it and allow whichProfile() to be called.
    delete require.cache[require.resolve('../lib/settings')]

  afterEach ->
    settings.switchProfile(originalProfile)
    delete require.cache[require.resolve('../lib/settings')]


  fit 'tests hiding and showing', ->
    waitsForPromise ->
      activationPromise

    runs ->
      # Test core:cancel
      atom.workspaceView.trigger 'spark-ide:select-core'
      expect(atom.workspaceView.find('#spark-ide-cores-view')).toExist()
      atom.workspaceView.trigger 'core:cancel'
      expect(atom.workspaceView.find('#spark-ide-cores-view')).not.toExist()

      # Test core:close
      atom.workspaceView.trigger 'spark-ide:select-core'
      expect(atom.workspaceView.find('#spark-ide-cores-view')).toExist()
      atom.workspaceView.trigger 'core:close'
      expect(atom.workspaceView.find('#spark-ide-login-view')).not.toExist()
