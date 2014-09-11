{WorkspaceView} = require 'atom'
$ = require('atom').$
SettingsHelper = require '../../lib/utils/settings-helper'

describe 'Cloud Variables and Functions View', ->
  activationPromise = null
  originalProfile = null
  sparkIde = null
  cloudVariablesAndFunctions = null

  beforeEach ->
    require '../../lib/vendor/ApiClient'
    atom.workspaceView = new WorkspaceView

    activationPromise = atom.packages.activatePackage('spark-ide').then ({mainModule}) ->
      sparkIde = mainModule
      sparkIde.cloudVariablesAndFunctions = null

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
      atom.workspaceView.trigger 'spark-ide:toggle-cloud-variables-and-functions'

      waitsFor ->
        !!sparkIde.cloudVariablesAndFunctions

      runs ->
        @cloudVariablesAndFunctions = sparkIde.cloudVariablesAndFunctions

        expect(atom.workspaceView.find('#spark-ide-cloud-variables-and-functions')).toExist()
        @cloudVariablesAndFunctions.toggle()
        expect(atom.workspaceView.find('#spark-ide-cloud-variables-and-functions')).not.toExist()

    it 'checks listing variables', ->
      require.cache[require.resolve('../../lib/vendor/ApiClient')].exports = require '../mocks/ApiClient-fail'
      atom.workspaceView.trigger 'spark-ide:toggle-cloud-variables-and-functions'

      waitsFor ->
        !!sparkIde.cloudVariablesAndFunctions

      runs ->
        @cloudVariablesAndFunctions = sparkIde.cloudVariablesAndFunctions

        body = @cloudVariablesAndFunctions.find('#spark-ide-cloud-variables > .panel-body')

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

        # TODO: Test for watch

        # Test refresh button
        spyOn @cloudVariablesAndFunctions, 'refreshVariable'
        body.find('table > tbody > tr:eq(0) > td:eq(3) > button').click()
        expect(@cloudVariablesAndFunctions.refreshVariable).toHaveBeenCalled()
        expect(@cloudVariablesAndFunctions.refreshVariable).toHaveBeenCalledWith('foo')
        jasmine.unspy @cloudVariablesAndFunctions, 'refreshVariable'

    it 'tests refreshing', ->
      require.cache[require.resolve('../../lib/vendor/ApiClient')].exports = require '../mocks/ApiClient-success'
      atom.workspaceView.trigger 'spark-ide:toggle-cloud-variables-and-functions'

      waitsFor ->
        !!sparkIde.cloudVariablesAndFunctions

      runs ->
        @cloudVariablesAndFunctions = sparkIde.cloudVariablesAndFunctions
        @body = @cloudVariablesAndFunctions.find('#spark-ide-cloud-variables > .panel-body')

      waitsFor ->
        @body.find('table > tbody > tr:eq(0) > td:eq(2)').text() == '1'

      runs ->
        expect(@body.find('table > tbody > tr:eq(0) > td:eq(2)').hasClass('loading')).toBe(false)

    it 'checks event hooks', ->
      require.cache[require.resolve('../../lib/vendor/ApiClient')].exports = require '../mocks/ApiClient-success'
      atom.workspaceView.trigger 'spark-ide:toggle-cloud-variables-and-functions'

      waitsFor ->
        !!sparkIde.cloudVariablesAndFunctions

      runs ->
        @cloudVariablesAndFunctions = sparkIde.cloudVariablesAndFunctions

        # Tests spark-ide:update-core-status
        spyOn @cloudVariablesAndFunctions, 'listVariables'
        spyOn @cloudVariablesAndFunctions, 'listFunctions'
        atom.workspaceView.trigger 'spark-ide:update-core-status'
        expect(@cloudVariablesAndFunctions.listVariables).toHaveBeenCalled()
        expect(@cloudVariablesAndFunctions.listFunctions).toHaveBeenCalled()
        jasmine.unspy @cloudVariablesAndFunctions, 'listVariables'
        jasmine.unspy @cloudVariablesAndFunctions, 'listFunctions'

        # Tests spark-ide:spark-ide:logout
        SettingsHelper.clearCredentials()
        spyOn @cloudVariablesAndFunctions, 'detach'
        atom.workspaceView.trigger 'spark-ide:logout'
        expect(@cloudVariablesAndFunctions.detach).toHaveBeenCalled()
        jasmine.unspy @cloudVariablesAndFunctions, 'detach'
        @cloudVariablesAndFunctions.detach()
