fs = null
settings = null
utilities = null
path = null
_s = null

module.exports =
  SettingsHelper: null
  MenuManager: null
  SerialHelper: null
  StatusView: null
  LoginView: null
  SelectCoreView: null
  RenameCoreView: null
  ClaimCoreView: null
  IdentifyCoreView: null
  ListeningModeView: null
  SelectPortView: null
  CompileErrorsView: null
  CloudVariablesAndFunctions: null
  SelectFirmwareView: null
  ApiClient: null

  statusView: null
  loginView: null
  selectCoreView: null
  renameCoreView: null
  claimCoreView: null
  identifyCoreView: null
  listeningModeView: null
  selectPortView: null
  compileErrorsView: null
  cloudVariablesAndFunctionsView: null
  selectFirmwareView: null

  removePromise: null
  listPortsPromise: null
  compileCloudPromise: null
  flashCorePromise: null

  activate: (state) ->
    # Require modules on activation
    @StatusView ?= require './views/status-bar-view'
    @SettingsHelper ?= require './utils/settings-helper'
    @MenuManager ?= require './utils/menu-manager'

    # Initialize views
    @statusView = new @StatusView()

    # Hooking up commands
    atom.workspaceView.command 'spark-ide:login', => @login()
    atom.workspaceView.command 'spark-ide:logout', => @logout()
    atom.workspaceView.command 'spark-ide:select-core', => @selectCore()
    atom.workspaceView.command 'spark-ide:rename-core', => @renameCore()
    atom.workspaceView.command 'spark-ide:remove-core', => @removeCore()
    atom.workspaceView.command 'spark-ide:claim-core', => @claimCore()
    atom.workspaceView.command 'spark-ide:identify-core', (event, port) => @identifyCore(port)
    atom.workspaceView.command 'spark-ide:compile-cloud', (event, thenFlash) => @compileCloud(thenFlash)
    atom.workspaceView.command 'spark-ide:show-compile-errors', => @showCompileErrors()
    atom.workspaceView.command 'spark-ide:toggle-cloud-variables-and-functions', => @toggleCloudVariablesAndFunctions()
    atom.workspaceView.command 'spark-ide:flash-cloud', (event, firmware) => @flashCloud(firmware)

    atom.workspaceView.command 'spark-ide:update-menu', => @MenuManager.update()

    @MenuManager.update()

  deactivate: ->
    @statusView?.destroy()

  serialize: ->

  configDefaults:
    deleteFirmwareAfterFlash: true

  initView: (name) ->
    _s ?= require 'underscore.string'
    className = ''
    for part in name.split '-'
      className += _s.capitalize part

    @[className] ?= require './views/' + name
    @[className.charAt(0).toLowerCase() + className.slice(1)] ?= new @[className]()

  # "Decorator" which runs callback only when user is logged in
  loginRequired: (callback) ->
    if !@SettingsHelper.isLoggedIn()
      return

    callback()

  # "Decorator" which runs callback only when user is logged in and has core selected
  coreRequired: (callback) ->
    if !@SettingsHelper.isLoggedIn()
      return

    if !@SettingsHelper.hasCurrentCore()
      return

    callback()

  # "Decorator" which runs callback only when there's project set
  projectRequired: (callback) ->
    if !atom.project.getPath()
      return

    callback()

  login: ->
    @initView 'login-view'
    # You may ask why this isn't in LoginView? This way, we don't need to
    # require/initialize login view until it's needed.
    atom.workspaceView.command 'spark-ide:cancel-login', => @loginView.cancelCommand()
    @loginView.show()

  logout: -> @loginRequired =>
    @initView 'login-view'

    @loginView.logout()

  selectCore: -> @loginRequired =>
    @initView 'select-core-view'

    @selectCoreView.show()

  renameCore: -> @coreRequired =>
    @RenameCoreView ?= require './views/rename-core-view'
    @renameCoreView ?= new @RenameCoreView(@SettingsHelper.get 'current_core_name')

    @renameCoreView.attach()

  removeCore: -> @coreRequired =>
    removeButton = 'Remove ' + @SettingsHelper.get('current_core_name')
    buttons = {}
    buttons['Cancel'] = ->

    buttons['Remove ' + @SettingsHelper.get('current_core_name')] = =>
      workspace = atom.workspaceView
      @ApiClient ?= require './vendor/ApiClient'
      client = new @ApiClient @SettingsHelper.get('apiUrl'), @SettingsHelper.get('access_token')
      @removePromise = client.removeCore @SettingsHelper.get('current_core')
      @removePromise.done (e) =>
        if !@removePromise
          return
        atom.workspaceView = workspace
        @SettingsHelper.clearCurrentCore()
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
      detailedMessage: 'Do you really want to remove ' + @SettingsHelper.get('current_core_name') + '?'
      buttons: buttons

  claimCore: -> @loginRequired =>
    @initView 'claim-core-view'

    @claimCoreView.attach()

  identifyCore: (port=null) -> @loginRequired =>
    @ListeningModeView ?= require './views/listening-mode-view'
    @SerialHelper ?= require './utils/serial-helper'

    @listPortsPromise = @SerialHelper.listPorts()
    @listPortsPromise.done (ports) =>
      @listPortsPromise = null
      if ports.length == 0
        @listeningModeView ?= new @ListeningModeView()
        @listeningModeView.show()
      else if (ports.length == 1) || (!!port)
        if !port
          port = ports[0].comName

        promise = @SerialHelper.askForCoreID port
        promise.done (coreID) =>
          @IdentifyCoreView ?= require './views/identify-core-view'
          @identifyCoreView = new @IdentifyCoreView coreID
          @identifyCoreView.attach()
        , (e) =>
          @statusView.setStatus e, 'error'
          @statusView.clearAfter 5000
      else
        @SelectPortView ?= require './views/select-port-view'
        @selectPortView ?= new @SelectPortView()

        @selectPortView.show()

  compileCloud: (thenFlash=null) -> @loginRequired => @projectRequired =>
    if !!@compileCloudPromise
      return

    @SettingsHelper.set 'compile-status', {working: true}
    atom.workspaceView.trigger 'spark-ide:update-compile-status'

    @ApiClient ?= require './vendor/ApiClient'
    client = new @ApiClient @SettingsHelper.get('apiUrl'), @SettingsHelper.get('access_token')

    # Including files
    fs ?= require 'fs-plus'
    settings ?= require './vendor/settings'
    utilities ?= require './vendor/utilities'

    rootPath = atom.project.getPath()
    files = fs.listSync(rootPath)
    files = files.filter (file) ->
      return !(utilities.getFilenameExt(file).toLowerCase() in settings.notSourceExtensions)

    workspace = atom.workspaceView
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
          atom.workspaceView = workspace
          @SettingsHelper.set 'compile-status', {filename: filename}
          atom.workspaceView.trigger 'spark-ide:update-compile-status'
          @downloadBinaryPromise = null

          # TODO: Test it
          if !!thenFlash
            atom.workspaceView.trigger 'spark-ide:flash-cloud'
      else
        # Handle errors
        @CompileErrorsView ?= require './views/compile-errors-view'
        @SettingsHelper.set 'compile-status', {errors: @CompileErrorsView.parseErrors(e.errors[0])}
        atom.workspaceView.trigger 'spark-ide:update-compile-status'
        atom.workspaceView.trigger 'spark-ide:show-compile-errors'
        @compileCloudPromise = null

  showCompileErrors: ->
    @initView 'compile-errors-view'

    @compileErrorsView.show()

  toggleCloudVariablesAndFunctions: -> @coreRequired =>
    @initView 'cloud-variables-and-functions-view'

    @cloudVariablesAndFunctionsView.toggle()

  flashCloud: (firmware=null) -> @coreRequired => @projectRequired =>
    fs ?= require 'fs-plus'
    utilities ?= require './vendor/utilities'

    rootPath = atom.project.getPath()
    files = fs.listSync(rootPath)
    files = files.filter (file) ->
      return (utilities.getFilenameExt(file).toLowerCase() == '.bin')

    if files.length == 0
      # If no firmware, compile
      atom.workspaceView.trigger 'spark-ide:compile-cloud', [true]
    else if (files.length == 1) || (!!firmware)
      # If one firmware, flash
      @ApiClient ?= require './vendor/ApiClient'
      client = new @ApiClient @SettingsHelper.get('apiUrl'), @SettingsHelper.get('access_token')

      if !firmware
        firmware = files[0]

      @statusView.setStatus 'Flashing via the cloud...'

      @flashCorePromise = client.flashCore @SettingsHelper.get('current_core'), {file: firmware}
      @flashCorePromise.done (e) =>
        console.log 'done', e
        @statusView.setStatus 'Flashing via the cloud...'

        if atom.config.get('spark-ide.deleteFirmwareAfterFlash')
          fs.unlink firmware

        @flashCorePromise = null
      , (e) =>
        console.error e
    else
      # If multiple firmware, show select
      @initView 'select-firmware-view'

      files.reverse()
      @selectFirmwareView.setItems files
      @selectFirmwareView.show()
