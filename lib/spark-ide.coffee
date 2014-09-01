fs = null
settings = null
utilities = null

SettingsHelper = null
MenuManager = null
SerialHelper = null
StatusView = null
LoginView = null
SelectCoreView = null
RenameCoreView = null
ClaimCoreView = null
IdentifyCoreView = null
ListeningModeView = null
SelectPortView = null
CompileErrorsView = null
ApiClient = null

module.exports =
  statusView: null
  loginView: null
  selectCoreView: null
  renameCoreView: null
  claimCoreView: null
  identifyCoreView: null
  listeningModeView: null
  selectPortView: null
  compileErrorsView: null

  removePromise: null
  listPortsPromise: null

  activate: (state) ->
    # Require modules on activation
    StatusView ?= require './views/status-bar-view'
    SettingsHelper ?= require './utils/settings-helper'
    MenuManager ?= require './utils/menu-manager'

    # Initialize views
    @statusView = new StatusView()

    # Hooking up commands
    atom.workspaceView.command 'spark-ide:login', => @login()
    atom.workspaceView.command 'spark-ide:logout', => @logout()
    atom.workspaceView.command 'spark-ide:select-core', => @selectCore()
    atom.workspaceView.command 'spark-ide:rename-core', => @renameCore()
    atom.workspaceView.command 'spark-ide:remove-core', => @removeCore()
    atom.workspaceView.command 'spark-ide:claim-core', => @claimCore()
    atom.workspaceView.command 'spark-ide:identify-core', (event, port) => @identifyCore(port)
    atom.workspaceView.command 'spark-ide:compile-cloud', => @compileCloud()
    atom.workspaceView.command 'spark-ide:show-compile-errors', => @showCompileErrors()

    atom.workspaceView.command 'spark-ide:update-menu', => MenuManager.update()

    MenuManager.update()

  deactivate: ->
    @statusView?.destroy()

  serialize: ->

  login: ->
    LoginView ?= require './views/login-view'
    @loginView ?= new LoginView()
    # You may ask why this isn't in LoginView? This way, we don't need to
    # require/initialize login view until it's needed.
    atom.workspaceView.command 'spark-ide:cancel-login', => @loginView.cancelCommand()
    @loginView.show()

  logout: ->
    if !SettingsHelper.isLoggedIn()
      return

    LoginView ?= require './views/login-view'
    @loginView ?= new LoginView()

    @loginView.logout()

  selectCore: ->
    SelectCoreView ?= require './views/select-core-view'
    @selectCoreView ?= new SelectCoreView()

    if !SettingsHelper.isLoggedIn()
      return

    @selectCoreView.show()

  renameCore: ->
    RenameCoreView ?= require './views/rename-core-view'

    if !SettingsHelper.isLoggedIn()
      return

    if !SettingsHelper.hasCurrentCore()
      return

    @renameCoreView = new RenameCoreView(SettingsHelper.get 'current_core_name')
    @renameCoreView.attach()

  removeCore: ->
    if !SettingsHelper.isLoggedIn()
      return

    if !SettingsHelper.hasCurrentCore()
      return

    removeButton = 'Remove ' + SettingsHelper.get('current_core_name')
    buttons = {}
    buttons['Cancel'] = ->

    buttons['Remove ' + SettingsHelper.get('current_core_name')] = =>
      workspace = atom.workspaceView
      ApiClient = require './vendor/ApiClient'
      client = new ApiClient SettingsHelper.get('apiUrl'), SettingsHelper.get('access_token')
      @removePromise = client.removeCore SettingsHelper.get('current_core')
      @removePromise.done (e) =>
        if !@removePromise
          return
        atom.workspaceView = workspace
        SettingsHelper.clearCurrentCore()
        atom.workspaceView.trigger 'spark-ide:update-core-status'
        atom.workspaceView.trigger 'spark-ide:update-menu'

        @removePromise = null
      , (e) =>
        @removePromise = null
        atom.confirm
          message: e.error
          detailedMessage: e.info

    atom.confirm
      message: 'Removal confirmation'
      detailedMessage: 'Do you really want to remove ' + SettingsHelper.get('current_core_name') + '?'
      buttons: buttons

  claimCore: ->
    ClaimCoreView ?= require './views/claim-core-view'

    if !SettingsHelper.isLoggedIn()
      return

    @claimCoreView = new ClaimCoreView()
    @claimCoreView.attach()

  identifyCore: (port=null) ->
    ListeningModeView ?= require './views/listening-mode-view'
    SerialHelper = require './utils/serial-helper'

    if !SettingsHelper.isLoggedIn()
      return

    @listPortsPromise = SerialHelper.listPorts()
    @listPortsPromise.done (ports) =>
      @listPortsPromise = null
      if ports.length == 0
        @listeningModeView = new ListeningModeView()
        @listeningModeView.show()
      else if (ports.length == 1) || (!!port)
        if !port
          port = ports[0].comName

        promise = SerialHelper.askForCoreID port
        promise.done (coreID) =>
          IdentifyCoreView ?= require './views/identify-core-view'
          @identifyCoreView = new IdentifyCoreView coreID
          @identifyCoreView.attach()
        , (e) =>
          @statusView.setStatus e, 'error'
          @statusView.clearAfter 5000
      else
        SelectPortView ?= require './views/select-port-view'
        @selectPortView ?= new SelectPortView()

        @selectPortView.show()

  parseErrors: (raw) ->
    lines = raw.split "\n"
    errors = []
    for line in lines
      result = line.match /^([^:]+):(\d+):(\d+):\s(\w+):(.*)$/
      if result and result[4] == 'error'
        errors.push {
          file: result[1],
          row: result[2],
          col: result[3],
          type: result[4],
          message: result[5]
        }
    errors

  compileCloud: ->
    if !SettingsHelper.isLoggedIn()
      return

    if !!@compileCloudPromise
      return

    if !atom.project.getRootDirectory()
      return

    localStorage.setItem('compile-status', JSON.stringify({working: true}))
    atom.workspaceView.trigger 'spark-ide:update-compile-status'

    ApiClient = require './vendor/ApiClient'
    client = new ApiClient SettingsHelper.get('apiUrl'), SettingsHelper.get('access_token')

    # Including files
    fs ?= require 'fs-plus'
    settings ?= require './vendor/settings'
    utilities ?= require './vendor/utilities'

    rootPath = atom.project.getRootDirectory().getPath()
    files = fs.listSync(rootPath)
    files = files.filter (file) ->
      return !(utilities.getFilenameExt(file).toLowerCase() in settings.notSourceExtensions)

    @compileCloudPromise = client.compileCode files
    @compileCloudPromise.done (e) =>
      if !e
        return

      if e.ok
        # Download binary
        @compileCloudPromise = null
        filename = 'firmware_' + (new Date()).getTime() + '.bin';
        @downloadBinaryPromise = client.downloadBinary e.binary_url, rootPath + '/' + filename
        @downloadBinaryPromise.done (e) =>
          localStorage.setItem('compile-status', JSON.stringify({filename: filename}))
          atom.workspaceView.trigger 'spark-ide:update-compile-status'
          @downloadBinaryPromise = null
      else
        # Handle errors
        localStorage.setItem('compile-status', JSON.stringify({errors: @parseErrors(e.errors[0])}))
        atom.workspaceView.trigger 'spark-ide:update-compile-status'
        @compileCloudPromise = null
        atom.workspaceView.trigger 'spark-ide:show-compile-errors'

  showCompileErrors: ->
    CompileErrorsView ?= require './views/compile-errors-view'
    @compileErrorsView = new CompileErrorsView
    @compileErrorsView.show()
