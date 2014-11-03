fs = null
settings = null
utilities = null
path = null
_s = null
url = null

module.exports =
  # Local modules for JIT require
  SettingsHelper: null
  MenuManager: null
  SerialHelper: null
  PathWatcher: null
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
  spark: null
  toolbar: null
  watchSubscription: null

  removePromise: null
  listPortsPromise: null
  compileCloudPromise: null
  flashCorePromise: null

  activate: (state) ->
    # Require modules on activation
    @StatusView ?= require './views/status-bar-view'
    @SettingsHelper ?= require './utils/settings-helper'
    @MenuManager ?= require './utils/menu-manager'
    @PathWatcher ?= require 'pathwatcher'

    # Initialize status bar view
    @statusView = new @StatusView()

    # Hook up commands
    atom.workspaceView.command 'spark-ide:login', => @login()
    atom.workspaceView.command 'spark-ide:logout', => @logout()
    atom.workspaceView.command 'spark-ide:select-core', => @selectCore()
    atom.workspaceView.command 'spark-ide:rename-core', => @renameCore()
    atom.workspaceView.command 'spark-ide:remove-core', => @removeCore()
    atom.workspaceView.command 'spark-ide:claim-core', => @claimCore()
    atom.workspaceView.command 'spark-ide:identify-core', (event, port) => @identifyCore(port)
    atom.workspaceView.command 'spark-ide:compile-cloud', (event, thenFlash) => @compileCloud(thenFlash)
    atom.workspaceView.command 'spark-ide:show-compile-errors', => @showCompileErrors()
    atom.workspaceView.command 'spark-ide:show-cloud-variables-and-functions', => @showCloudVariablesAndFunctions()
    atom.workspaceView.command 'spark-ide:flash-cloud', (event, firmware) => @flashCloud(firmware)
    atom.workspaceView.command 'spark-ide:show-serial-monitor', => @showSerialMonitor()
    atom.workspaceView.command 'spark-ide:setup-wifi', (event, port) => @setupWifi(port)
    atom.workspaceView.command 'spark-ide:enter-wifi-credentials', (event, port, ssid, security) => @enterWifiCredentials(port, ssid, security)

    atom.workspaceView.command 'spark-ide:update-menu', => @MenuManager.update()

    # Update menu (default one in CSON file is empty)
    @MenuManager.update()

    url = require 'url'
    atom.workspace.addOpener (uriToOpen) =>
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'spark-ide:'

      @initView pathname.substr(1)

    # Updating toolbar
    try
      atom.packages.activatePackage('toolbar')
        .then (pkg) =>
          @toolbar = pkg.mainModule
          @toolbar.appendSpacer()
          @flashButton = @toolbar.appendButton 'flash', 'spark-ide:flash-cloud', 'Compile and upload code using cloud', 'ion'
          @compileButton = @toolbar.appendButton 'checkmark-circled', 'spark-ide:compile-cloud', 'Compile and show errors if any', 'ion'

          @toolbar.appendSpacer()

          @toolbar.appendButton 'document-text', ->
            require('shell').openExternal('http://docs.spark.io/')
          , 'Opens reference at docs.spark.io', 'ion'
          @coreButton = @toolbar.appendButton 'pinpoint', 'spark-ide:select-core', 'Select which Core you want to work on', 'ion'
          @wifiButton = @toolbar.appendButton 'wifi', 'spark-ide:setup-wifi', 'Setup Core\'s WiFi credentials', 'ion'
          @toolbar.appendButton 'usb', 'spark-ide:show-serial-monitor', 'Show serial monitor', 'ion'

          @updateToolbarButtons()

      atom.workspaceView.command 'spark-ide:update-login-status', =>
        @updateToolbarButtons()

      atom.workspaceView.command 'spark-ide:update-core-status', =>
        @updateToolbarButtons()
    catch

    # Monitoring changes in settings
    settings ?= require './vendor/settings'
    fs ?= require 'fs-plus'
    path ?= require 'path'

    proFile = path.join settings.ensureFolder(), 'profile.json'
    if !fs.existsSync(proFile)
      fs.writeFileSync proFile, '{}'

    if typeof(jasmine) == 'undefined'
      # Don't watch settings during tests
      @profileSubscription ?= @PathWatcher.watch proFile, (eventType) =>
        if eventType is 'change' and @profileSubscription?
          @configSubscription?.close()
          @configSubscription = null
          @watchConfig()
          @updateToolbarButtons()
          @MenuManager.update()
          atom.workspaceView.trigger 'spark-ide:update-login-status'

      @watchConfig()

  deactivate: ->
    @statusView?.destroy()

  serialize: ->

  config:
    # Delete .bin file after flash
    deleteFirmwareAfterFlash:
      type: 'boolean'
      default: true

  # Require view's module and initialize it
  initView: (name) ->
    _s ?= require 'underscore.string'

    name += '-view'
    className = ''
    for part in name.split '-'
      className += _s.capitalize part

    @[className] ?= require './views/' + name
    key = className.charAt(0).toLowerCase() + className.slice(1)
    @[key] ?= new @[className]()
    @[key]

  # "Decorator" which runs callback only when user is logged in
  loginRequired: (callback) ->
    if !@SettingsHelper.isLoggedIn()
      return

    @spark ?= require 'spark'
    @spark.login { accessToken: @SettingsHelper.get('access_token') }

    callback()

  # "Decorator" which runs callback only when user is logged in and has core selected
  coreRequired: (callback) ->
    @loginRequired =>
      if !@SettingsHelper.hasCurrentCore()
        return

      callback()

  # "Decorator" which runs callback only when there's project set
  projectRequired: (callback) ->
    if atom.project.getPaths().length == 0
      return

    callback()

  # Open view in bottom panel
  openPane: (uri) ->
    uri = 'spark-ide://editor/' + uri
    pane = atom.workspace.paneForUri uri

    if pane?
      pane.activateItemForUri uri
    else
      if atom.workspaceView.getPaneViews().length == 1
        pane = atom.workspaceView.getActivePaneView().splitDown()
      else
        paneViews = atom.workspaceView.getPaneViews()
        pane = paneViews[paneViews.length - 1]
        pane = pane.splitRight()

      pane.activate()
      atom.workspace.open uri, searchAllPanes: true

  # Enables/disables toolbar buttons based on log in state
  updateToolbarButtons: ->
    if @SettingsHelper.isLoggedIn()
      @compileButton.setEnabled true
      @coreButton.setEnabled true
      @wifiButton.setEnabled true

      if @SettingsHelper.hasCurrentCore()
        @flashButton.setEnabled true
      else
        @flashButton.setEnabled false
    else
      @flashButton.setEnabled false
      @compileButton.setEnabled false
      @coreButton.setEnabled false
      @wifiButton.setEnabled false

  # Watch config file for changes
  watchConfig: ->
    settings.whichProfile()
    settingsFile = settings.findOverridesFile()
    if !fs.existsSync(settingsFile)
      fs.writeFileSync settingsFile, '{}'

    @configSubscription ?= @PathWatcher.watch settingsFile, (eventType) =>
      if eventType is 'change' and @configSubscription? and @accessToken != @SettingsHelper.get('access_token')
        @accessToken = @SettingsHelper.get 'access_token'
        @updateToolbarButtons()
        @MenuManager.update()
        atom.workspaceView.trigger 'spark-ide:update-login-status'

  # Function for selecting port or showing Listen dialog
  choosePort: (delegate) ->
    @ListeningModeView ?= require './views/listening-mode-view'
    @SerialHelper ?= require './utils/serial-helper'
    @listPortsPromise = @SerialHelper.listPorts()
    @listPortsPromise.done (ports) =>
      @listPortsPromise = null
      if ports.length == 0
        # If there are no ports, show dialog with animation how to enter listening mode
        @listeningModeView = new @ListeningModeView(delegate)
        @listeningModeView.show()
      else if ports.length == 1
        atom.workspaceView.trigger delegate, [ports[0].comName]
      else
        # There are at least two ports so show them and ask user to choose
        @SelectPortView ?= require './views/select-port-view'
        @selectPortView = new @SelectPortView(delegate)

        @selectPortView.show()

  # Show login dialog
  login: ->
    @initView 'login'
    # You may ask why commands aren't registered in LoginView?
    # This way, we don't need to require/initialize login view until it's needed.
    atom.workspaceView.command 'spark-ide:cancel-login', => @loginView.cancelCommand()
    @loginView.show()

  # Log out current user
  logout: -> @loginRequired =>
    @initView 'login'

    @loginView.logout()

  # Show user's cores list
  selectCore: -> @loginRequired =>
    @initView 'select-core'

    @selectCoreView.show()

  # Show rename core dialog
  renameCore: -> @coreRequired =>
    @RenameCoreView ?= require './views/rename-core-view'
    @renameCoreView = new @RenameCoreView(@SettingsHelper.get 'current_core_name')

    @renameCoreView.attach()

  # Remove current core from user's account
  removeCore: -> @coreRequired =>
    removeButton = 'Remove ' + @SettingsHelper.get('current_core_name')
    buttons = {}
    buttons['Cancel'] = ->

    buttons['Remove ' + @SettingsHelper.get('current_core_name')] = =>
      workspace = atom.workspaceView
      @removePromise = @spark.removeCore @SettingsHelper.get('current_core')
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
        if e.code == 'ENOTFOUND'
          message = 'Error while connecting to ' + e.hostname
        else
          message = e.info
        atom.confirm
          message: 'Error'
          detailedMessage: message

    atom.confirm
      message: 'Removal confirmation'
      detailedMessage: 'Do you really want to remove ' + @SettingsHelper.get('current_core_name') + '?'
      buttons: buttons

  # Show core claiming dialog
  claimCore: -> @loginRequired =>
    @claimCoreView = null
    @initView 'claim-core'

    @claimCoreView.attach()

  # Identify core via serial
  identifyCore: (port=null) -> @loginRequired =>
    if !port
      @choosePort('spark-ide:identify-core')
    else
      promise = @SerialHelper.askForCoreID port
      promise.done (coreID) =>
        @IdentifyCoreView ?= require './views/identify-core-view'
        @identifyCoreView = new @IdentifyCoreView coreID
        @identifyCoreView.attach()
      , (e) =>
        @statusView.setStatus e, 'error'
        @statusView.clearAfter 5000

  # Compile current project in the cloud
  compileCloud: (thenFlash=null) -> @loginRequired => @projectRequired =>
    if !!@compileCloudPromise
      return

    @SettingsHelper.set 'compile-status', {working: true}
    atom.workspaceView.trigger 'spark-ide:update-compile-status'

    # Including files
    fs ?= require 'fs-plus'
    path ?= require 'path'
    settings ?= require './vendor/settings'
    utilities ?= require './vendor/utilities'

    rootPath = atom.project.getPaths()[0]
    files = fs.listSync(rootPath)
    files = files.filter (file) ->
      return !(utilities.getFilenameExt(file).toLowerCase() in settings.notSourceExtensions)

    process.chdir rootPath
    files = (path.relative(rootPath, file) for file in files)

    workspace = atom.workspaceView
    @compileCloudPromise = @spark.compileCode files
    @compileCloudPromise.done (e) =>
      if !e
        return

      if e.ok
        # Download binary
        @compileCloudPromise = null
        filename = 'firmware_' + (new Date()).getTime() + '.bin';
        @downloadBinaryPromise = @spark.downloadBinary e.binary_url, rootPath + '/' + filename

        @downloadBinaryPromise.done (e) =>
          atom.workspaceView = workspace
          @SettingsHelper.set 'compile-status', {filename: filename}
          atom.workspaceView.trigger 'spark-ide:update-compile-status'
          @downloadBinaryPromise = null

          if !!thenFlash
            atom.workspaceView.trigger 'spark-ide:flash-cloud'
      else
        # Handle errors
        @CompileErrorsView ?= require './views/compile-errors-view'
        @SettingsHelper.set 'compile-status', {errors: @CompileErrorsView.parseErrors(e.errors[0])}
        atom.workspaceView.trigger 'spark-ide:update-compile-status'
        atom.workspaceView.trigger 'spark-ide:show-compile-errors'
        @compileCloudPromise = null
    , (e) =>
      console.error e
      @SettingsHelper.set 'compile-status', null
      atom.workspaceView.trigger 'spark-ide:update-compile-status'

  # Show compile errors list
  showCompileErrors: ->
    @initView 'compile-errors'

    @compileErrorsView.show()

  # Show cloud variables and functions panel
  showCloudVariablesAndFunctions: -> @coreRequired =>
    @cloudVariablesAndFunctionsView = null
    @openPane 'cloud-variables-and-functions'

  # Flash core via the cloud
  flashCloud: (firmware=null) -> @coreRequired => @projectRequired =>
    fs ?= require 'fs-plus'
    path ?= require 'path'
    utilities ?= require './vendor/utilities'

    rootPath = atom.project.getPaths()[0]
    files = fs.listSync(rootPath)
    files = files.filter (file) ->
      return (utilities.getFilenameExt(file).toLowerCase() == '.bin')

    if files.length == 0
      # If no firmware file, compile
      atom.workspaceView.trigger 'spark-ide:compile-cloud', [true]
    else if (files.length == 1) || (!!firmware)
      # If one firmware file, flash

      if !firmware
        firmware = files[0]

      process.chdir rootPath
      firmware = path.relative rootPath, firmware

      @statusView.setStatus 'Flashing via the cloud...'

      @flashCorePromise = @spark.flashCore @SettingsHelper.get('current_core'), [firmware]
      @flashCorePromise.done (e) =>
        @statusView.setStatus e.status + '...'
        @statusView.clearAfter 5000

        if atom.config.get 'spark-ide.deleteFirmwareAfterFlash'
          fs.unlink firmware

        @flashCorePromise = null
      , (e) =>
        @statusView.setStatus e.message, 'error'
        @statusView.clearAfter 5000
    else
      # If multiple firmware files, show select
      @initView 'select-firmware'

      files.reverse()
      @selectFirmwareView.setItems files
      @selectFirmwareView.show()

  # Show serial monitor panel
  showSerialMonitor: ->
    @serialMonitorView = null
    @openPane 'serial-monitor'

  # Set up core's WiFi
  setupWifi: (port=null) -> @loginRequired =>
    if !port
      @choosePort 'spark-ide:setup-wifi'
    else
      @initView 'select-wifi'
      @selectWifiView.port = port
      @selectWifiView.show()

  enterWifiCredentials: (port, ssid=null, security=null) -> @loginRequired =>
    if !port
      return

    @wifiCredentialsView = null
    @initView 'wifi-credentials'
    @wifiCredentialsView.port = port
    @wifiCredentialsView.show(ssid, security)
