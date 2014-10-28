{WorkspaceView} = require 'atom'
$ = require('atom').$
SettingsHelper = require '../../lib/utils/settings-helper'
SparkStub = require '../stubs/spark'

describe 'Cloud Variables and Functions View', ->
  activationPromise = null
  originalProfile = null
  sparkIde = null
  cloudVariablesAndFunctionsView = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView

    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
      sparkIde = mainModule
      sparkIde.cloudVariablesAndFunctionsView = null

    originalProfile = SettingsHelper.getProfile()
    # For tests not to mess up our profile, we have to switch to test one...
    SettingsHelper.setProfile 'spark-ide-test'

    waitsForPromise ->
      activationPromise

  afterEach ->
    SettingsHelper.setProfile originalProfile

  describe '', ->
    beforeEach ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      SettingsHelper.set 'variables', {foo: 'int32'}
      SettingsHelper.set 'functions', ['bar']

    afterEach ->
      SettingsHelper.clearCurrentCore()
      SettingsHelper.clearCredentials()
      SettingsHelper.set 'variables', {}
      SettingsHelper.set 'functions', []

    it 'checks hiding and showing', ->
      SparkStub.stubSuccess 'getVariable'
      sparkIde.cloudVariablesAndFunctionsView = null
      atom.workspaceView.trigger 'spark-ide:show-cloud-variables-and-functions'

      waitsFor ->
        !!sparkIde.cloudVariablesAndFunctionsView && sparkIde.cloudVariablesAndFunctionsView.hasParent()

      runs ->
        @cloudVariablesAndFunctionsView = sparkIde.cloudVariablesAndFunctionsView

        expect(atom.workspaceView.find('#spark-ide-cloud-variables-and-functions')).toExist()
        @cloudVariablesAndFunctionsView.close()
        expect(atom.workspaceView.find('#spark-ide-cloud-variables-and-functions')).not.toExist()

    it 'checks listing variables', ->
      SparkStub.stubFail 'getVariable'
      atom.workspaceView.trigger 'spark-ide:show-cloud-variables-and-functions'

      waitsFor ->
        !!sparkIde.cloudVariablesAndFunctionsView

      runs ->
        @cloudVariablesAndFunctionsView = sparkIde.cloudVariablesAndFunctionsView
        spyOn @cloudVariablesAndFunctionsView, 'refreshVariable'
        SparkStub.stubSuccess 'getVariable'

      waitsFor ->
        @cloudVariablesAndFunctionsView.hasParent()

      runs ->
        body = @cloudVariablesAndFunctionsView.find('#spark-ide-cloud-variables > .panel-body')

        expect(body.find('table')).toExist()

        expect(body.find('table > thead')).toExist()
        expect(body.find('table > thead > tr')).toExist()
        expect(body.find('table > thead > tr > th:eq(0)').text()).toEqual('Name')
        expect(body.find('table > thead > tr > th:eq(1)').text()).toEqual('Type')
        expect(body.find('table > thead > tr > th:eq(2)').text()).toEqual('Value')
        expect(body.find('table > thead > tr > th:eq(3)').text()).toEqual('Refresh')

        expect(body.find('table > tbody')).toExist()
        expect(body.find('table > tbody > tr')).toExist()
        expect(body.find('table > tbody > tr').length).toEqual(1)
        expect(body.find('table > tbody > tr:eq(0) > td:eq(0)').text()).toEqual('foo')
        expect(body.find('table > tbody > tr:eq(0) > td:eq(1)').text()).toEqual('int32')
        expect(body.find('table > tbody > tr:eq(0) > td:eq(2)').text()).toEqual('')
        expect(body.find('table > tbody > tr:eq(0) > td:eq(2)').hasClass('loading')).toBe(true)
        expect(body.find('table > tbody > tr:eq(0) > td:eq(3) > button')).toExist()
        expect(body.find('table > tbody > tr:eq(0) > td:eq(3) > button').hasClass('icon-sync')).toBe(true)

        expect(body.find('table > tbody > tr:eq(0) > td:eq(4) > button')).toExist()
        expect(body.find('table > tbody > tr:eq(0) > td:eq(4) > button').hasClass('icon-eye')).toBe(true)

        # Test refresh button
        body.find('table > tbody > tr:eq(0) > td:eq(3) > button').click()
        expect(@cloudVariablesAndFunctionsView.refreshVariable).toHaveBeenCalled()
        expect(@cloudVariablesAndFunctionsView.refreshVariable).toHaveBeenCalledWith('foo')
        jasmine.unspy @cloudVariablesAndFunctionsView, 'refreshVariable'

    it 'tests refreshing', ->
      SparkStub.stubSuccess 'getVariable'
      atom.workspaceView.trigger 'spark-ide:show-cloud-variables-and-functions'

      waitsFor ->
        !!sparkIde.cloudVariablesAndFunctionsView && sparkIde.cloudVariablesAndFunctionsView.hasParent()

      runs ->
        @cloudVariablesAndFunctionsView = sparkIde.cloudVariablesAndFunctionsView
        @body = @cloudVariablesAndFunctionsView.find('#spark-ide-cloud-variables > .panel-body')

      waitsFor ->
        @body.find('table > tbody > tr:eq(0) > td:eq(2)').text() == '1'

      runs ->
        expect(@body.find('table > tbody > tr:eq(0) > td:eq(2)').hasClass('loading')).toBe(false)

    it 'checks event hooks', ->
      SparkStub.stubSuccess 'getVariable'
      atom.workspaceView.trigger 'spark-ide:show-cloud-variables-and-functions'

      waitsFor ->
        !!sparkIde.cloudVariablesAndFunctionsView && sparkIde.cloudVariablesAndFunctionsView.hasParent()

      runs ->
        @cloudVariablesAndFunctionsView = sparkIde.cloudVariablesAndFunctionsView

        # Tests spark-ide:update-core-status
        spyOn @cloudVariablesAndFunctionsView, 'listVariables'
        spyOn @cloudVariablesAndFunctionsView, 'listFunctions'
        spyOn @cloudVariablesAndFunctionsView, 'clearWatchers'
        atom.workspaceView.trigger 'spark-ide:core-status-updated'
        expect(@cloudVariablesAndFunctionsView.listVariables).toHaveBeenCalled()
        expect(@cloudVariablesAndFunctionsView.listFunctions).toHaveBeenCalled()
        expect(@cloudVariablesAndFunctionsView.clearWatchers).toHaveBeenCalled()
        jasmine.unspy @cloudVariablesAndFunctionsView, 'listVariables'
        jasmine.unspy @cloudVariablesAndFunctionsView, 'listFunctions'
        jasmine.unspy @cloudVariablesAndFunctionsView, 'clearWatchers'

        # Tests spark-ide:spark-ide:logout
        SettingsHelper.clearCredentials()
        spyOn @cloudVariablesAndFunctionsView, 'close'
        spyOn @cloudVariablesAndFunctionsView, 'clearWatchers'
        atom.workspaceView.trigger 'spark-ide:logout'
        expect(@cloudVariablesAndFunctionsView.close).toHaveBeenCalled()
        expect(@cloudVariablesAndFunctionsView.clearWatchers).toHaveBeenCalled()
        jasmine.unspy @cloudVariablesAndFunctionsView, 'close'
        jasmine.unspy @cloudVariablesAndFunctionsView, 'clearWatchers'
        @cloudVariablesAndFunctionsView.detach()

    it 'check watching variable', ->
      SparkStub.stubSuccess 'getVariable'
      atom.workspaceView.trigger 'spark-ide:show-cloud-variables-and-functions'

      waitsFor ->
        !!sparkIde.cloudVariablesAndFunctionsView && sparkIde.cloudVariablesAndFunctionsView.hasParent()

      runs ->
        @cloudVariablesAndFunctionsView = sparkIde.cloudVariablesAndFunctionsView

        row = @cloudVariablesAndFunctionsView.find('#spark-ide-cloud-variables > .panel-body table > tbody > tr:eq(0)')

        watchButton = row.find('td:eq(4) > button')
        refreshButton = row.find('td:eq(3) > button')

        expect(refreshButton.attr('disabled')).not.toEqual('disabled')
        expect(watchButton.hasClass('selected')).toBe(false)
        expect(Object.keys(@cloudVariablesAndFunctionsView.watchers).length).toEqual(0)

        jasmine.Clock.useMock()
        spyOn @cloudVariablesAndFunctionsView, 'refreshVariable'

        watchButton.click()

        expect(refreshButton.attr('disabled')).toEqual('disabled')
        expect(watchButton.hasClass('selected')).toBe(true)
        expect(Object.keys(@cloudVariablesAndFunctionsView.watchers).length).toEqual(1)
        expect(Object.keys(@cloudVariablesAndFunctionsView.watchers)).toEqual(['foo'])
        expect(@cloudVariablesAndFunctionsView.refreshVariable).not.toHaveBeenCalled()
        watcher = @cloudVariablesAndFunctionsView.watchers['foo']

        jasmine.Clock.tick(5001)

        expect(@cloudVariablesAndFunctionsView.refreshVariable).toHaveBeenCalled()
        expect(@cloudVariablesAndFunctionsView.refreshVariable).toHaveBeenCalledWith('foo')

        spyOn window, 'clearInterval'

        expect(window.clearInterval).not.toHaveBeenCalled()

        watchButton.click()

        expect(refreshButton.attr('disabled')).not.toEqual('disabled')
        expect(watchButton.hasClass('selected')).toBe(false)
        expect(Object.keys(@cloudVariablesAndFunctionsView.watchers).length).toEqual(0)
        expect(window.clearInterval).toHaveBeenCalled()
        expect(window.clearInterval).toHaveBeenCalledWith(watcher)

        # TODO: Test clearing all watchers

        jasmine.unspy window, 'clearInterval'
        jasmine.unspy @cloudVariablesAndFunctionsView, 'refreshVariable'
        @cloudVariablesAndFunctionsView.detach()

    it 'checks clearing watchers', ->
      SparkStub.stubSuccess 'getVariable'
      atom.workspaceView.trigger 'spark-ide:show-cloud-variables-and-functions'

      waitsFor ->
        !!sparkIde.cloudVariablesAndFunctionsView && sparkIde.cloudVariablesAndFunctionsView.hasParent()

      runs ->
        @cloudVariablesAndFunctionsView = sparkIde.cloudVariablesAndFunctionsView
        @cloudVariablesAndFunctionsView.watchers['foo'] = 'bar'
        spyOn window, 'clearInterval'
        expect(window.clearInterval).not.toHaveBeenCalled()

        expect(Object.keys(@cloudVariablesAndFunctionsView.watchers).length).toEqual(1)
        @cloudVariablesAndFunctionsView.clearWatchers()

        expect(window.clearInterval).toHaveBeenCalled()
        expect(window.clearInterval).toHaveBeenCalledWith('bar')
        expect(Object.keys(@cloudVariablesAndFunctionsView.watchers).length).toEqual(0)

        jasmine.unspy window, 'clearInterval'
        @cloudVariablesAndFunctionsView.detach()

    # TODO: Test functions
