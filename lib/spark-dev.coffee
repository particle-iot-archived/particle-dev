CompositeDisposable = null
Emitter = null
fs = null
settings = null
utilities = null
path = null
_s = null
url = null
errorParser = null

module.exports =
  # Local modules for JIT require
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
  SelectFirmwareView: null
  File: null

  statusView: null
  loginView: null
  selectCoreView: null
  renameCoreView: null
  claimCoreView: null
  identifyCoreView: null
  listeningModeView: null
  selectPortView: null
  compileErrorsView: null
  selectFirmwareView: null
  spark: null
  toolbar: null

  removePromise: null
  listPortsPromise: null
  compileCloudPromise: null
  flashCorePromise: null

  activate: (state) ->
    # Require modules on activation
    @StatusView ?= require './views/status-bar-view'
    @SettingsHelper ?= require './utils/settings-helper'
    @MenuManager ?= require './utils/menu-manager'
    {@File} = require 'atom'

    # Install packages we depend on
    require('atom-package-deps').install('spark-dev', true)

    @workspaceElement = atom.views.getView(atom.workspace)
    {CompositeDisposable, Emitter} = require 'atom'
    @disposables = new CompositeDisposable
    @emitter = new Emitter
    atom.sparkDev =
      emitter: @emitter

    # Initialize status bar view
    @statusView = new @StatusView()

    # Hook up commands
    @disposables.add atom.commands.add 'atom-workspace',
      'spark-dev:login': => @login()
      'spark-dev:logout': => @logout()
      'spark-dev:select-device': => @selectCore()
      'spark-dev:rename-device': => @renameCore()
      'spark-dev:remove-device': => @removeCore()
      'spark-dev:claim-device': => @claimCore()
      'spark-dev:try-flash-usb': => @tryFlashUsb()
      'spark-dev:update-menu': => @MenuManager.update()
      'spark-dev:show-compile-errors': => @showCompileErrors()
      'spark-dev:show-serial-monitor': => @showSerialMonitor()
      'spark-dev:identify-device': => @identifyCore()
      'spark-dev:compile-cloud': => @compileCloud()
      'spark-dev:flash-cloud': => @flashCloud()
      'spark-dev:flash-cloud-file': (event) => @flashCloudFile event
      'spark-dev:setup-wifi': => @setupWifi()
      'spark-dev:enter-wifi-credentials': => @enterWifiCredentials()

    # Hook up events
    @emitter.on 'spark-dev:identify-device', (event) =>
      @identifyCore(event.port)

    @emitter.on 'spark-dev:compile-cloud', (event) =>
      @compileCloud(event.thenFlash)

    @emitter.on 'spark-dev:flash-cloud', (event) =>
      @flashCloud(event.firmware)

    @emitter.on 'spark-dev:setup-wifi', (event) =>
      @setupWifi(event.port)

    @emitter.on 'spark-dev:enter-wifi-credentials', (event) =>
      @enterWifiCredentials(event.port, event.ssid, event.security)

    # Update menu (default one in CSON file is empty)
    @MenuManager.update()

    url = require 'url'
    atom.workspace.addOpener (uriToOpen) =>
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'spark-dev:'

      try
        @initView pathname.substr(1)
      catch
        return

    # Updating toolbar
    @disposables.add atom.commands.add 'atom-workspace',
      'spark-dev:update-login-status': => @updateToolbarButtons()
      'spark-dev:update-core-status': => @updateToolbarButtons()

    # Monitoring changes in settings
    settings ?= require './vendor/settings'
    fs ?= require 'fs-plus'
    path ?= require 'path'

    proFile = path.join settings.ensureFolder(), 'profile.json'
    if !fs.existsSync(proFile)
      fs.writeFileSync proFile, '{}'
      console.log '!Created profile ' + proFile

    if typeof(jasmine) == 'undefined'
      # Don't watch settings during tests
      profileFile = new @File(proFile)
      profileFile.onDidChange =>
        @watchConfig()
        @updateToolbarButtons()
        @MenuManager.update()
        atom.commands.dispatch @workspaceElement, 'spark-dev:update-login-status'

      @watchConfig()

  deactivate: ->
    @statusView?.destroy()
    @emitter.dispose()
    @disposables.dispose()
    @statusBarTile?.destroy()
    @statusBarTile = null

  serialize: ->

  provideParticleDev: ->
    @

  consumeStatusBar: (statusBar) ->
    @statusView.addTiles statusBar
    # @statusBarTile = statusBar.addLeftTile(item: @statusView, priority: 100)
    @statusView.updateLoginStatus()

  consumeToolBar: (toolBar) ->
    @toolBar = toolBar 'spark-dev-tool-bar'

    @toolBar.addSpacer()
    @flashButton = @toolBar.addButton
      icon: 'flash'
      callback: 'spark-dev:flash-cloud'
      tooltip: 'Flash'
      iconset: 'ion'
      priority: 51
    @compileButton = @toolBar.addButton
      icon: 'android-cloud-done'
      callback: 'spark-dev:compile-cloud'
      tooltip: 'Verify'
      iconset: 'ion'
      priority: 52

    @toolBar.addSpacer
      priority: 53

    @toolBar.addButton
      icon: 'document-text'
      callback: ->
        require('shell').openExternal('https://docs.particle.io/')
      tooltip: 'Opens reference at docs.particle.io'
      iconset: 'ion'
      priority: 54
    @coreButton = @toolBar.addButton
      icon: 'pinpoint'
      callback: 'spark-dev:select-device'
      tooltip: 'Devices'
      iconset: 'ion'
      priority: 55
    @wifiButton = @toolBar.addButton
      icon: 'wifi'
      callback: 'spark-dev:setup-wifi'
      tooltip: 'Setup device\'s WiFi credentials'
      iconset: 'ion'
      priority: 56
    @toolBar.addButton
      icon: 'usb'
      callback: 'spark-dev:show-serial-monitor'
      tooltip: 'Show serial monitor'
      iconset: 'ion'
      priority: 57

    @updateToolbarButtons()

  consumeConsolePanel: (@consolePanel) ->

  config:
    # Delete .bin file after flash
    deleteFirmwareAfterFlash:
      type: 'boolean'
      default: true

    # Delete old .bin files on successful compile
    deleteOldFirmwareAfterCompile:
      type: 'boolean'
      default: true

    # Files ignored when compiling
    filesExcludedFromCompile:
      type: 'string'
      default: '.ds_store, .jpg, .gif, .png, .include, .ignore, Thumbs.db, .git, .bin'

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
    @spark.login
      accessToken: @SettingsHelper.get('access_token')

    if @SettingsHelper.getApiUrl()
      @spark.api.baseUrl = @SettingsHelper.getApiUrl()

    callback()

  # "Decorator" which runs callback only when user is logged in and has core selected
  deviceRequired: (callback) ->
    @loginRequired =>
      if !@SettingsHelper.hasCurrentCore()
        atom.notifications.addInfo 'Please select a device'
        return

      callback()

  # "Decorator" which runs callback only when there's project set
  projectRequired: (callback) ->
    if @getProjectDir() == null
      atom.notifications.addInfo 'Please open a directory with your project'
      return

    callback()

  # Open view in bottom panel
  openPane: (uri) ->
    uri = 'spark-dev://editor/' + uri
    pane = atom.workspace.paneForURI uri

    if pane?
      pane.activateItemForURI uri
    else
      if atom.workspace.getPanes().length == 1
        pane = atom.workspace.getActivePane().splitDown()
      else
        panes = atom.workspace.getPanes()
        pane = panes.pop()
        pane = pane.splitRight()

      pane.activate()
      atom.workspace.open uri, searchAllPanes: true

  # Enables/disables toolbar buttons based on log in state
  updateToolbarButtons: ->
    return unless @compileButton
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
      console.log '!Created ' + settingsFile
      fs.writeFileSync settingsFile, '{}'

    configFile = new @File(settingsFile)
    configFile.onDidChange =>
      @accessToken = @SettingsHelper.get 'access_token'
      @updateToolbarButtons()
      @MenuManager.update()
      atom.commands.dispatch @workspaceElement, 'spark-dev:update-login-status'

  processDirIncludes: (dirname) ->
    settings ?= require './vendor/settings'
    utilities ?= require './vendor/utilities'

    dirname = path.resolve dirname
    includesFile = path.join dirname, settings.dirIncludeFilename
    ignoreFile = path.join dirname, settings.dirExcludeFilename
    ignores = []
    includes = [
      "**/*.h",
      "**/*.ino",
      "**/*.cpp",
      "**/*.c"
    ]

    if fs.existsSync(includesFile)
      # Grab and process all the files in the include file.
      # cleanIncludes = utilities.trimBlankLinesAndComments(utilities.readAndTrimLines(includesFile))
      # includes = utilities.fixRelativePaths dirname, cleanIncludes
      null

    files = utilities.globList dirname, includes

    notSourceExtensions = atom.config.get('spark-dev.filesExcludedFromCompile').split ','
    ignores = ('**/*' + _s.trim(extension).toLowerCase() for extension in notSourceExtensions)

    if fs.existsSync(ignoreFile)
      cleanIgnores = utilities.readAndTrimLines ignoreFile
      ignores = ignores.concat utilities.trimBlankLinesAndComments cleanIgnores

    ignoredFiles = utilities.globList dirname, ignores
    utilities.compliment files, ignoredFiles

  # Function for selecting port or showing Listen dialog
  choosePort: (delegate) ->
    @ListeningModeView ?= require './views/listening-mode-view'
    @SerialHelper ?= require './utils/serial-helper'
    @listPortsPromise = @SerialHelper.listPorts()
    @listPortsPromise.then (ports) =>
      @listPortsPromise = null
      if ports.length == 0
        # If there are no ports, show dialog with animation how to enter listening mode
        @listeningModeView = new @ListeningModeView(delegate)
        @listeningModeView.show()
      else if ports.length == 1
        @emitter.emit delegate, {port: ports[0].comName}
      else
        # There are at least two ports so show them and ask user to choose
        @SelectPortView ?= require './views/select-port-view'
        @selectPortView = new @SelectPortView(delegate)

        @selectPortView.show()
    , (e) =>
      console.error e

  getCurrentPlatform: ->
    currentPlatform = 'core'
    if @SettingsHelper.hasCurrentCore()
      switch @SettingsHelper.getLocal('current_core_platform')
        when 6 then currentPlatform = 'photon'
        when 8 then currentPlatform = 'p1'
        when 10 then currentPlatform = 'electron'

    currentPlatform

  getProjectDir: ->
    paths = atom.project.getDirectories()
    if paths.length == 0
      return null

    # For now take first directory
    # FIXME: some way to let user choose which dir to use
    projectPath = paths[0]

    if !projectPath.existsSync()
      return null

    projectDir = projectPath.getPath()
    if !fs.lstatSync(projectDir).isDirectory()
      atom.project.removePath(projectDir)
      projectDir = projectPath.getParent().getPath()
      atom.project.addPath(projectDir)
      return projectDir
    projectPath.getPath()

  requestErrorHandler: (error) ->
    if error.message == 'invalid_token'
      @statusView.setStatus 'Token expired. Log in again', 'error'
      @statusView.clearAfter 5000
      @logout()

  # Show login dialog
  login: ->
    @initView 'login'
    # You may ask why commands aren't registered in LoginView?
    # This way, we don't need to require/initialize login view until it's needed.
    @disposables.add atom.commands.add 'atom-workspace',
      'spark-dev:cancel-login': => @loginView.cancelCommand()
    @loginView.show()

  # Log out current user
  logout: -> @loginRequired =>
    @initView 'login'

    @loginView.logout()

  # Show user's cores list
  selectCore: -> @loginRequired =>
    @initView 'select-core'
    @selectCoreView.spark ?= @spark
    @selectCoreView.requestErrorHandler = (error) =>
      @requestErrorHandler error

    @selectCoreView.show()

  # Show rename core dialog
  renameCore: -> @deviceRequired =>
    @RenameCoreView ?= require './views/rename-core-view'
    @renameCoreView = new @RenameCoreView(@SettingsHelper.getLocal 'current_core_name')

    @renameCoreView.attach()

  # Remove current core from user's account
  removeCore: -> @deviceRequired =>
    removeButton = 'Remove ' + @SettingsHelper.getLocal('current_core_name')
    buttons = {}
    buttons['Cancel'] = ->

    buttons['Remove ' + @SettingsHelper.getLocal('current_core_name')] = =>
      @removePromise = @spark.removeCore @SettingsHelper.getLocal('current_core')
      @removePromise.then (e) =>
        if !@removePromise
          return
        @SettingsHelper.clearCurrentCore()
        atom.commands.dispatch @workspaceElement, 'spark-dev:update-core-status'
        atom.commands.dispatch @workspaceElement, 'spark-dev:update-menu'

        @removePromise = null
      , (e) =>
        @removePromise = null
        @requestErrorHandler e
        if e.code == 'ENOTFOUND'
          message = 'Error while connecting to ' + e.hostname
        else
          message = e.info
        atom.confirm
          message: 'Error'
          detailedMessage: message

    atom.confirm
      message: 'Removal confirmation'
      detailedMessage: 'Do you really want to remove ' + @SettingsHelper.getLocal('current_core_name') + '?'
      buttons: buttons

  # Show core claiming dialog
  claimCore: -> @loginRequired =>
    @claimCoreView = null
    @initView 'claim-core'

    @claimCoreView.attach()

  # Identify core via serial
  identifyCore: (port=null) -> @loginRequired =>
    if !port
      @choosePort('spark-dev:identify-device')
    else
      @SerialHelper ?= require './utils/serial-helper'
      promise = @SerialHelper.askForCoreID port
      promise.then (coreID) =>
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

    # Including files
    fs ?= require 'fs-plus'
    path ?= require 'path'
    settings ?= require './vendor/settings'
    utilities ?= require './vendor/utilities'
    _s ?= require 'underscore.string'

    rootPath = @getProjectDir()
    files = @processDirIncludes rootPath
    process.chdir rootPath
    files = (path.relative(rootPath, file) for file in files)

    if files.length == 0
      @statusView.setStatus 'No .ino/.cpp file to compile', 'warning'
      @statusView.clearAfter 5000
      return

    @SettingsHelper.setLocal 'compile-status', {working: true}
    atom.commands.dispatch @workspaceElement, 'spark-dev:update-compile-status'

    invalidFiles = files.filter (file) ->
      path.basename(file).indexOf(' ') > -1
    if invalidFiles.length
      errors = []
      for file in invalidFiles
        errors.push
          file: file,
          message: 'File contains space in its name'
          row: 0,
          col: 0

      @CompileErrorsView ?= require './views/compile-errors-view'
      @SettingsHelper.setLocal 'compile-status', {errors: errors}
      atom.commands.dispatch @workspaceElement, 'spark-dev:show-compile-errors'
      atom.commands.dispatch @workspaceElement, 'spark-dev:update-compile-status'
      return

    options = {}
    if @SettingsHelper.hasCurrentCore()
      options.productID = @SettingsHelper.getLocal('current_core_platform')
    currentPlatform = @getCurrentPlatform()

    @compileCloudPromise = @spark.compileCode files, options
    @compileCloudPromise.then (e) =>
      if !e
        return

      if e.ok
        # Download binary
        @compileCloudPromise = null

        if atom.config.get('spark-dev.deleteOldFirmwareAfterCompile')
          # Remove old firmwares
          files = fs.listSync rootPath
          for file in files
            if _s.startsWith(path.basename(file), currentPlatform + '_firmware') and _s.endsWith(file, '.bin')
              if fs.existsSync file
                fs.unlinkSync file

        filename = currentPlatform + '_firmware_' + (new Date()).getTime() + '.bin';
        @downloadBinaryPromise = @spark.downloadBinary e.binary_url, rootPath + '/' + filename

        @downloadBinaryPromise.then (e) =>
          @SettingsHelper.setLocal 'compile-status', {filename: filename}
          atom.commands.dispatch @workspaceElement, 'spark-dev:update-compile-status'
          if !!thenFlash
            setTimeout =>
              atom.commands.dispatch @workspaceElement, 'spark-dev:flash-cloud'
              @downloadBinaryPromise = null
            , 500
          else
            @downloadBinaryPromise = null
        , (e) =>
          @requestErrorHandler e
      else
        # Handle errors
        @CompileErrorsView ?= require './views/compile-errors-view'
        errorParser ?= require 'gcc-output-parser'
        if e.errors && e.errors.length
          errors = errorParser.parseString(e.errors[0]).filter (message) ->
            message.type.indexOf('error') > -1

          if errors.length == 0
            @SettingsHelper.setLocal 'compile-status', {error: e.output}
          else
            @SettingsHelper.setLocal 'compile-status', {errors: errors}
            atom.commands.dispatch @workspaceElement, 'spark-dev:show-compile-errors'
        else
          @SettingsHelper.setLocal 'compile-status', {error: e.output}

        atom.commands.dispatch @workspaceElement, 'spark-dev:update-compile-status'
        @compileCloudPromise = null
    , (e) =>
      @requestErrorHandler e
      @SettingsHelper.setLocal 'compile-status', null
      atom.commands.dispatch @workspaceElement, 'spark-dev:update-compile-status'

  # Show compile errors list
  showCompileErrors: ->
    @initView 'compile-errors'

    @compileErrorsView.show()

  # Flash core via the cloud
  flashCloud: (firmware=null) -> @deviceRequired => @projectRequired =>
    fs ?= require 'fs-plus'
    path ?= require 'path'
    _s ?= require 'underscore.string'
    utilities ?= require './vendor/utilities'

    currentPlatform = @getCurrentPlatform()
    rootPath = @getProjectDir()
    files = fs.listSync(rootPath)
    files = files.filter (file) ->
      return (utilities.getFilenameExt(file).toLowerCase() == '.bin') &&
             (_s.startsWith(path.basename(file), currentPlatform))

    if files.length == 0 && (!firmware)
      # If no firmware file, compile
      @emitter.emit 'spark-dev:compile-cloud', {thenFlash: true}
    else if (files.length == 1) || (!!firmware)
      # If one firmware file, flash

      if !firmware
        firmware = files[0]

      flashDevice = =>
        process.chdir rootPath
        firmware = path.relative rootPath, firmware

        @statusView.setStatus 'Flashing via the cloud...'

        @flashCorePromise = @spark.flashCore @SettingsHelper.getLocal('current_core'), [firmware]
        @flashCorePromise.then (e) =>
          if e.ok
            @statusView.setStatus e.status + '...'
            @statusView.clearAfter 5000

            if atom.config.get 'spark-dev.deleteFirmwareAfterFlash'
              if fs.existsSync firmware
                fs.unlink firmware
          else
            error = e.errors?[0]?.error
            @statusView.setStatus error, 'error'
            @statusView.clearAfter 5000

          @flashCorePromise = null
        , (e) =>
          @requestErrorHandler e
          if e.code == 'ECONNRESET'
            @statusView.setStatus 'Device seems to be offline', 'error'
          else
            @statusView.setStatus e.message, 'error'
          @statusView.clearAfter 5000
          @flashCorePromise = null

      if @SettingsHelper.getLocal('current_core_platform') == 10
        atom.confirm
          message: 'Flashing over cellular'
          detailedMessage: 'You\'re trying to flash your app to ' +
            @SettingsHelper.getLocal('current_core_name') +
            ' over cellular. This will use at least a few KB from your
            data plan. ' +
            'Instead it\'s recommended to flash
            it via USB.'
          buttons:
            'Cancel': ->
            'Flash OTA anyway': =>
              flashDevice()
      else
        flashDevice()
    else
      # If multiple firmware files, show select
      @initView 'select-firmware'

      files.reverse()
      @selectFirmwareView.setItems files
      @selectFirmwareView.show()

  flashCloudFile: (event) ->
    @flashCloud event.target.dataset.path

  # Show serial monitor panel
  showSerialMonitor: ->
    @serialMonitorView = null
    @openPane 'serial-monitor'

  # Set up core's WiFi
  setupWifi: (port=null) -> @loginRequired =>
    if !port
      @choosePort 'spark-dev:setup-wifi'
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

  tryFlashUsb: -> @projectRequired =>
    if !atom.commands.registeredCommands['spark-dev-dfu-util:flash-usb']
      # TODO: Ask for installation
    else
      atom.commands.dispatch @workspaceElement, 'spark-dev-dfu-util:flash-usb'
