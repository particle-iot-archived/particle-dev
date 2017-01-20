CompositeDisposable = null
Emitter = null
fs = null
settings = null
utilities = null
path = null
_s = null
url = null
errorParser = null
libraryManager = null
semver = null

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

  packageName: require './utils/package-helper'

  activate: (state) ->
    # Require modules on activation
    @StatusView ?= require './views/status-bar-view'
    @SettingsHelper ?= require './utils/settings-helper'
    @MenuManager ?= require './utils/menu-manager'
    {@File} = require 'atom'

    # Install packages we depend on
    require('atom-package-deps').install(@packageName(), true)

    @workspaceElement = atom.views.getView(atom.workspace)
    {CompositeDisposable, Emitter} = require 'atom'
    @disposables = new CompositeDisposable
    @contextMenus = new CompositeDisposable
    @emitter = new Emitter
    atom.particleDev =
      emitter: @emitter

    # Initialize status bar view
    @statusView = new @StatusView()

    # Hook up commands
    commands = {}
    commands["#{@packageName()}:login"] = => @login()
    commands["#{@packageName()}:logout"] = => @logout()
    commands["#{@packageName()}:select-device"] = => @selectCore()
    commands["#{@packageName()}:rename-device"] = => @renameCore()
    commands["#{@packageName()}:remove-device"] = => @removeCore()
    commands["#{@packageName()}:claim-device"] = => @claimCore()
    commands["#{@packageName()}:try-flash-usb"] = => @tryFlashUsb()
    commands["#{@packageName()}:update-menu"] = => @MenuManager.update()
    commands["#{@packageName()}:show-compile-errors"] = => @showCompileErrors()
    commands["#{@packageName()}:show-serial-monitor"] = => @showSerialMonitor()
    commands["#{@packageName()}:identify-device"] = => @identifyCore()
    commands["#{@packageName()}:compile-cloud"] = => @compileCloud()
    commands["#{@packageName()}:flash-cloud"] = => @flashCloud()
    commands["#{@packageName()}:flash-cloud-file"] = (event) => @flashCloudFile event
    commands["#{@packageName()}:flash-cloud-example-file"] = (event) => @flashCloudExampleFile event
    commands["#{@packageName()}:setup-wifi"] = => @setupWifi()
    commands["#{@packageName()}:enter-wifi-credentials"] = => @enterWifiCredentials()
    @disposables.add atom.commands.add 'atom-workspace', commands

    # Hook up events
    @emitter.on "#{@packageName()}:identify-device", (event) =>
      @identifyCore(event.port)

    @emitter.on "#{@packageName()}:select-device", (event) =>
      @selectCore(event.callback)

    @emitter.on "#{@packageName()}:compile-cloud", (event) =>
      @compileCloud(event.thenFlash, event.files, event.rootPath)

    @emitter.on "#{@packageName()}:flash-cloud", (event) =>
      @flashCloud(event.firmware)

    @emitter.on "#{@packageName()}:flash-cloud-example", (event) =>
      @flashCloudExample(event.file)

    @emitter.on "#{@packageName()}:setup-wifi", (event) =>
      @setupWifi(event.port)

    @emitter.on "#{@packageName()}:enter-wifi-credentials", (event) =>
      @enterWifiCredentials(event.port, event.ssid, event.security)

    # Update menu (default one in CSON file is empty)
    @MenuManager.update()

    url = require 'url'
    atom.workspace.addOpener (uriToOpen) =>
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is "#{@packageName()}:"

      try
        @initView pathname.substr(1)
      catch
        return

    # Updating toolbar
    commands = {}
    commands["#{@packageName()}:update-login-status"] = => @updateToolbarButtons()
    commands["#{@packageName()}:update-core-status"] = => @updateToolbarButtons()
    @disposables.add atom.commands.add 'atom-workspace', commands

    self = @
    flashExampleMenuItem = [{
      label: 'Flash Example OTA',
      command: "#{@packageName()}:flash-cloud-example-file",
      shouldDisplay: (event) => @isLibraryExampleSync(event.target.dataset.path),
      created: (event) ->
        this.enabled = self.canCompileNow()
    }]

    contextMenus = {
      '.tree-view.full-menu [is="tree-view-file"] [data-name$=".cpp"]':flashExampleMenuItem,
      '.tree-view.full-menu [is="tree-view-file"] [data-name$=".ino"]':flashExampleMenuItem,
# when matching the directory, the item is also propagated to all child elements of that directory regardless
# of their extension, so for now compiling an example is done only from the files themselves
#      '.tree-view.full-menu [is="tree-view-directory"]':flashExampleMenuItem
    }

    @contextMenus.add atom.contextMenu.add contextMenus

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
        atom.commands.dispatch @workspaceElement, "#{@packageName()}:update-login-status"

      @watchConfig()

    @disposables.add @watchEditors()
    @disposables.add atom.project.onDidChangePaths =>
      @updateToolbarButtons()

  deactivate: ->
    @statusView?.destroy()
    @emitter.dispose()
    @disposables.dispose()
    @contextMenus.dispose()
    @statusBarTile?.destroy()
    @statusBarTile = null
    @toolBar?.removeItems();
    @toolBar = null

  serialize: ->

  provideParticleDev: ->
    @

  consumeStatusBar: (statusBar) ->
    @statusView.addTiles statusBar
    # @statusBarTile = statusBar.addLeftTile(item: @statusView, priority: 100)
    @statusView.updateLoginStatus()

  consumeToolBar: (toolBar) ->
    @toolBar = toolBar "#{@packageName()}-tool-bar"

    @toolBar.addSpacer()
    @flashButton = @toolBar.addButton
      icon: 'flash'
      callback: "#{@packageName()}:flash-cloud"
      tooltip: 'Compile in cloud and upload code using cloud'
      iconset: 'ion'
      priority: 510
    @compileButton = @toolBar.addButton
      icon: 'android-cloud-done'
      callback: "#{@packageName()}:compile-cloud"
      tooltip: 'Compile in cloud and show errors if any'
      iconset: 'ion'
      priority: 520

    @toolBar.addSpacer
      priority: 530

    @toolBar.addButton
      icon: 'document-text'
      callback: ->
        require('shell').openExternal('https://docs.particle.io/')
      tooltip: 'Opens reference at docs.particle.io'
      iconset: 'ion'
      priority: 540
    @coreButton = @toolBar.addButton
      icon: 'pinpoint'
      callback: "#{@packageName()}:select-device"
      tooltip: 'Select which device you want to work on'
      iconset: 'ion'
      priority: 550
    @toolBar.addButton
      icon: 'stats-bars'
      callback: ->
        require('shell').openExternal('https://console.particle.io/')
      tooltip: 'Opens Console at console.particle.io'
      iconset: 'ion'
      priority: 560
    @toolBar.addButton
      icon: 'usb'
      callback: "#{@packageName()}:show-serial-monitor"
      tooltip: 'Show serial monitor'
      iconset: 'ion'
      priority: 570

    @updateToolbarButtons()

  consumeConsolePanel: (@consolePanel) ->

  consumeProfiles: (@profileManager) ->

  config:
    # Delete .bin file after flash
    deleteFirmwareAfterFlash:
      type: 'boolean'
      default: true

    # Delete old .bin files on successful compile
    deleteOldFirmwareAfterCompile:
      type: 'boolean'
      default: true

    # Save all files before compile
    saveAllBeforeCompile:
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
      self = this
      if !@SettingsHelper.hasCurrentCore()
        notification = atom.notifications.addInfo('Please select a device', {
          buttons: [
            { text: 'Select Device...', onDidClick: () =>
              # this is NotificationElement (UI), not Notification (the model)
              # hmm...doesn't seem to even be NotificationElement but the raw DOM object
              view = atom.views.getView(notification)
              view.removeNotification()
              @emitter.emit "#{@packageName()}:select-device", {callback}
            }
          ]
        })
        return
      callback()

  # "Decorator" which runs callback only when there's project set
  projectRequired: (callback) ->
    if @getProjectDir() == null
      atom.notifications.addInfo 'Please open a directory with your project'
      return

    callback()

  # "Decorator" which tests if we're using at least 0.5.3 when compiling with libraries
  minBuildTargetRequired: (callback) ->
    if @isProject() or @isLibrary()
      semver ?= require 'semver'
      defaultBuildTarget = @SettingsHelper.getLocal('current_core_default_build_target')
      if defaultBuildTarget && semver.lt(defaultBuildTarget, '0.5.3')
        atom.notifications.addError 'This project is only compatible with Particle system firmware v0.5.3 or later. You will need to update the system firmware running on your Electron before you can flash this project to your device.'
        return

    callback()

  # Open view in a panel
  openPane: (uri, location='bottom', packageName) ->
    if packageName
      uri = "#{packageName}://editor/" + uri
    else
      uri = "#{@packageName()}://editor/" + uri
    pane = atom.workspace.paneForURI uri

    if pane?
      pane.activateItemForURI uri
    else
      if atom.workspace.getPanes().length == 1
        switch location
          when 'bottom' then pane = atom.workspace.getActivePane().splitDown()
          when 'top' then pane = atom.workspace.getActivePane().splitUp()
          when 'left' then pane = atom.workspace.getActivePane().splitLeft()
          when 'right' then pane = atom.workspace.getActivePane().splitRight()
      else
        panes = atom.workspace.getPanes()
        pane = panes.pop()
        if location == 'left'
          pane = pane.splitLeft()
        else
          pane = pane.splitRight()

      pane.activate()
      atom.workspace.open uri, searchAllPanes: true

  isCompileAvailable: ->
    return (not @isLibrary() or @isLibraryExampleInFocus())

  isLibraryExampleInFocus: (editor=atom.workspace.getActiveTextEditor()) ->
    if editor
      file = editor.getPath()
      result =  @isLibraryExampleSync(file)
      return file if result

  # Enables/disables toolbar buttons based on log in state
  updateToolbarButtons: ->
    return unless @compileButton
    if @SettingsHelper.isLoggedIn()
      @compileButton.setEnabled @isCompileAvailable()
      @coreButton.setEnabled true

      if @SettingsHelper.hasCurrentCore()
        @flashButton.setEnabled @isCompileAvailable()
      else
        @flashButton.setEnabled false
    else
      @flashButton.setEnabled false
      @compileButton.setEnabled false
      @coreButton.setEnabled false

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
      atom.commands.dispatch @workspaceElement, "#{@packageName()}:update-login-status"

  watchEditors: ->
    return atom.workspace.onDidStopChangingActivePaneItem  (panel) =>
      if atom.workspace.isTextEditor(panel) and @isLibrary()
        @updateToolbarButtons()


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
      "**/*.c",
      "**/*.properties"
    ]

    if fs.existsSync(includesFile)
      # Grab and process all the files in the include file.
      # cleanIncludes = utilities.trimBlankLinesAndComments(utilities.readAndTrimLines(includesFile))
      # includes = utilities.fixRelativePaths dirname, cleanIncludes
      null

    files = utilities.globList dirname, includes

    notSourceExtensions = atom.config.get("#{@packageName()}.filesExcludedFromCompile").split ','
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

  getPlatformSlug: (id) ->
    slug = @profileManager.knownTargetPlatforms[id]
    if slug
      slug = slug.name
    else
      slug = 'Unknown'
    return _s.underscored slug

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

  existsProjectFile: (file) ->
    dir = @getProjectDir()
    return dir and fs.existsSync(path.join(dir, file))

  isProject: ->
    @existsProjectFile 'project.properties'

  isLibrary: ->
    @existsProjectFile 'library.properties'

  isLegacyLibrary: ->
    @existsProjectFile 'spark.json'


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
    commands = {}
    commands["#{@packageName}:cancel-login"] = => @loginView.cancelCommand()
    @disposables.add atom.commands.add 'atom-workspace', commands
    @loginView.show()

  # Log out current user
  logout: -> @loginRequired =>
    @initView 'login'

    @loginView.logout()

  # Show user's cores list
  selectCore: (callback) -> @loginRequired =>
    @initView 'select-core'
    @selectCoreView.profileManager = @profileManager
    @selectCoreView.requestErrorHandler = (error) =>
      @requestErrorHandler error

    @selectCoreView.show(callback)

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
        atom.commands.dispatch @workspaceElement, "#{@packageName()}:update-core-status"
        atom.commands.dispatch @workspaceElement, "#{@packageName()}:update-menu"

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
      @choosePort("#{@packageName()}:identify-device")
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

  canCompileNow: ->
    !@compileCloudPromise

  mapCommonPrefix: (files, basePath=process.cwd()) ->
    relative = []
    libraryManager ?= require 'particle-library-manager'
    libraryManager.pathsCommonPrefix files, relative, basePath
    map = {}
    for i in [0..files.length-1]
      map[relative[i]] = files[i]
    return map

  # Compile current project in the cloud
  # when updating arguments here, also update the event emitter above
  compileCloud: (thenFlash=null, files=null, rootPath=null) -> @loginRequired => @minBuildTargetRequired =>
    if !@canCompileNow
      return

    # this method should be refactored into 2
    # one part that determines what to compile (from context)
    # another part that expects the files and everything to compile to be provided
    # currently they are both bundled here which requires some recursive calls
    if not files and @isLibrary()
      focus = @isLibraryExampleInFocus()
      if focus
        @flashCloudExample focus, not thenFlash
        return

    # Including files
    fs ?= require 'fs-plus'
    path ?= require 'path'
    settings ?= require './vendor/settings'
    utilities ?= require './vendor/utilities'
    _s ?= require 'underscore.string'

    # if the files have been specified explicitly, assume project etc.. has already been checked for
    rootPath ?= @projectRequired => @getProjectDir()
    files ?= @processDirIncludes rootPath

    # files may also be a map from logical name to physical file name
    map = if Array.isArray(files) then @mapCommonPrefix files, rootPath else files
    files = (v for k, v of map)
    if files.length == 0
      @statusView.setStatus 'No .ino/.cpp file to compile', 'warning'
      @statusView.clearAfter 5000
      return

    if atom.config.get("#{@packageName()}.saveAllBeforeCompile")
      atom.commands.dispatch @workspaceElement, 'window:save-all'

    @SettingsHelper.setLocal 'compile-status', {working: true}
    atom.commands.dispatch @workspaceElement, "#{@packageName()}:update-compile-status"

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
      atom.commands.dispatch @workspaceElement, "#{@packageName()}:show-compile-errors"
      atom.commands.dispatch @workspaceElement, "#{@packageName()}:update-compile-status"
      return

    process.chdir rootPath
    libraryManager ?= require 'particle-library-manager'
    filesObject = {}
    console.info 'Compiling following files:', files
    for server, local of map
      filesObject[server] = fs.readFileSync(local)
    console.log 'filesObject', filesObject

    targetPlatformId = @profileManager.currentTargetPlatform
    targetPlatformSlug = @getPlatformSlug targetPlatformId
    @compileCloudPromise = @profileManager.apiClient.compileCode filesObject, targetPlatformId
    @compileCloudPromise.then (value) =>
      e = value.body
      if !e
        return

      if e.ok
        # Download binary
        @compileCloudPromise = null

        if atom.config.get("#{@packageName()}.deleteOldFirmwareAfterCompile")
          # Remove old firmwares
          files = fs.listSync rootPath
          for file in files
            if _s.startsWith(path.basename(file), targetPlatformSlug + '_firmware') and _s.endsWith(file, '.bin')
              if fs.existsSync file
                fs.unlinkSync file

        filename = targetPlatformSlug + '_firmware_' + (new Date()).getTime() + '.bin';
        @downloadBinaryPromise = @spark.downloadBinary e.binary_url, rootPath + '/' + filename

        @downloadBinaryPromise.then (e) =>
          @SettingsHelper.setLocal 'compile-status', {filename: filename}
          atom.commands.dispatch @workspaceElement, "#{@packageName()}:update-compile-status"
          if !!thenFlash
            # want to explicitly set the file to flash since we cannot assume it from the current project when compiling a library example
            @emitter.emit "#{@packageName()}:flash-cloud", {firmware: filename}
          else
            @downloadBinaryPromise = null
        , (e) =>
          @requestErrorHandler e
      else
        console.log e

    , (reason) =>
      e = reason.body
      console.warn('Compilation failed. Reason:', e);
      @CompileErrorsView ?= require './views/compile-errors-view'
      errorParser ?= require 'gcc-output-parser'
      # todo - also map from server filenames back to local filenames
      if e?.errors && e.errors.length
        errors = errorParser.parseString(e.errors[0]).filter (message) ->
          message.type.indexOf('error') > -1

        if errors.length == 0
          @SettingsHelper.setLocal 'compile-status', {error: e.output}
        else
          @SettingsHelper.setLocal 'compile-status', {errors: errors}
          atom.commands.dispatch @workspaceElement, "#{@packageName()}:show-compile-errors"
      else
        console.error 'Compilation failed with unexpected reason:', reason
        @SettingsHelper.setLocal 'compile-status', {error: e.output}

      atom.commands.dispatch @workspaceElement, "#{@packageName()}:update-compile-status"
      @compileCloudPromise = null

  # Show compile errors list
  showCompileErrors: ->
    @initView 'compile-errors'

    @compileErrorsView.show()

  # Flash core via the cloud
  flashCloud: (firmware=null) -> @deviceRequired =>
    fs ?= require 'fs-plus'
    path ?= require 'path'
    _s ?= require 'underscore.string'
    utilities ?= require './vendor/utilities'
    console.log 'flashCloud', firmware

    targetPlatformSlug = @getPlatformSlug @profileManager.currentTargetPlatform

    files = null
    rootPath = null
    if firmware
      files = [firmware]
    else
      if @isLibrary()
        focus = @isLibraryExampleInFocus()
        if focus
          @flashCloudExample focus
          return

      @projectRequired =>
        rootPath = @getProjectDir()
        files = fs.listSync(rootPath)
        files = files.filter (file) ->
          return (utilities.getFilenameExt(file).toLowerCase() == '.bin') &&
                 (_s.startsWith(path.basename(file), targetPlatformSlug))

    if files.length is 0
      # If no firmware file, compile
      @emitter.emit "#{@packageName()}:compile-cloud", {thenFlash: true}
    else if (files.length == 1)
      # If one firmware file, flash
      firmware = files[0]
      flashDevice = =>
        if !!rootPath
          process.chdir rootPath
          firmware = path.relative rootPath, firmware

        @statusView.setStatus 'Flashing via the cloud...'

        @flashCorePromise = @spark.flashCore @SettingsHelper.getLocal('current_core'), [firmware]
        @flashCorePromise.then (e) =>
          if e.ok == false
            error = e.errors?[0]?.error
            @statusView.setStatus error, 'error'
            @statusView.clearAfter 5000
          else
            @statusView.setStatus e.status + '...'
            @statusView.clearAfter 5000

            if atom.config.get "#{@packageName()}.deleteFirmwareAfterFlash"
              if fs.existsSync firmware
                fs.unlink firmware

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


  isLibraryExampleSync: (file) ->
    # todo - move to lib manager
    path ?= require 'path'
    fs ?= require 'fs'
    try
      stat = fs.statSync file
      if stat.isFile()
        file = path.dirname file
      examples = path.dirname file
      libroot = path.dirname examples
      split = examples.split path.sep
      properties = path.join libroot, 'library.properties'
      propertiesExists = fs.existsSync properties
      examplesDirectory = split[split.length-1]
      propertiesExists and examples and examplesDirectory=='examples'
    catch ex
      false

  isLibraryExample: (file) ->
    libraryManager ?= require 'particle-library-manager'
    libraryManager.isLibraryExample file

  flashCloudExample: (file, compileOnly) ->
    libraryManager ?= require('particle-library-manager')
    libraryManager.isLibraryExample path.basename(file), path.dirname(file)
      .then (example) =>
        if example
          console.log('example is', example)
          files = {}
          example.buildFiles(files)
            .then =>
              console.log('compiling example files', files)
              @emitter.emit "#{@packageName()}:compile-cloud", {thenFlash: not compileOnly, files: files.map, rootPath: files.basePath}

  flashCloudFile: (event) -> @deviceRequired =>
    @flashCloud event.target.dataset.path

  flashCloudExampleFile: (event) -> @deviceRequired =>
    file = event.target.dataset.path
    @emitter.emit "#{@packageName()}:flash-cloud-example", {file}

  # Show serial monitor panel
  showSerialMonitor: ->
    @serialMonitorView = null
    @openPane 'serial-monitor'

  # Set up core's WiFi
  setupWifi: (port=null) -> @loginRequired =>
    if !port
      @choosePort "#{@packageName()}:setup-wifi"
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
    atom.notifications.addWarning 'Flashing via USB from Particle Dev has not yet been implemented'
    if !atom.commands.registeredCommands["#{@packageName()}-dfu-util:flash-usb"]
      # TODO: Ask for installation
    else
      atom.commands.dispatch @workspaceElement, "#{@packageName()}-dfu-util:flash-usb"
