{View} = require 'atom'
SerialHelper = null
Subscriber = null

module.exports =
class CompileCloudView extends View
  @content: ->
    @div class: 'overlay from-top', =>
      @div class: 'block', =>
        @span 'Compiling in the cloud... '
        @span class: 'text-subtle', =>
          @text 'Cancel it with the '
          @span class: 'highlight', 'esc'
          @span ' key'

      @p id: 'spark-compile-cloud-loading', =>
        @span class: 'loading loading-spinner-large inline-block'

      @div id: 'spark-compile-cloud-success', =>
        @span class: 'inline-block highlight-success', 'Success'
        @div class: 'line', =>
          @span 'Code'
          @span class: 'highlight', outlet: 'sizeCode', '73kB'
        @div class: 'line', =>
          @span 'Initialized variables'
          @span class: 'highlight', outlet: 'sizeInitialized', '1kB'
        @div class: 'line', =>
          @span 'Uninitialized variables'
          @span class: 'highlight', outlet: 'sizeUninitialized', '80kB'
        @div class: 'line', =>
          @span =>
            @span 'Saved to '
            @span class: 'highlight', outlet: 'filename', 'firmware_12345678.bin'

      @div id: 'spark-compile-cloud-fail', =>
        @div id: 'errors', =>
          @div class: 'text-error', '4'
          @span class: 'icon icon-issue-opened highlight-error', 'Compile errors'


      @div class: 'block', =>
        # @button click: 'cancel', class: 'btn btn-error', 'Show errors'
        @button click: 'cancel', class: 'btn', 'Cancel'

  initialize: (serializeState) ->
    {Subscriber} = require 'emissary'

    @prop 'id', 'spark-ide-compile-cloud-view'

    # Subscribe to Atom's core:cancel core:close events
    @subscriber = new Subscriber()
    @subscriber.subscribeToCommand atom.workspaceView, 'core:cancel core:close', ({target}) =>
      @hide()

  serialize: ->

  destroy: ->
    @detach()

  show: ->
    if !@hasParent()
      atom.workspaceView.append(this)

  hide: ->
    if @hasParent()
      @detach()

  cancel: (event, element) ->
    atom.workspaceView.trigger 'core:cancel'
