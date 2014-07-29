{WorkspaceView} = require 'atom'
SparkIde = require '../lib/spark-ide'

describe "SparkIdeStatusBarView", ->
  activationPromise = null
  statusBarPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    statusBarPromise = atom.packages.activatePackage('status-bar')
    activationPromise = atom.packages.activatePackage('spark-ide')

  describe "when the spark-ide is activated", ->
    beforeEach ->
      waitsForPromise ->
        activationPromise
      waitsForPromise ->
        statusBarPromise

    it "attaches custom status bar", ->
      statusBar = atom.workspaceView.statusBar.find('#spark-ide-status-bar-view')
      expect(statusBar).toExist()
      expect(statusBar.find('#spark-icon')).toExist()
