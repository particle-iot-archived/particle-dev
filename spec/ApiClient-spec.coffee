ApiClient = require '../lib/ApiClient'
ApiClient = require './mocks/ApiClient-credentials'

describe "Tests for mocked ApiClient library", ->
  loginSucceeded = true
  client = null
  promise = null

  beforeEach ->
    client = new ApiClient "https://api.spark.io"

  it "passes fake credentials", ->
    promise = client.login "spark-ide", "foo@bar.com", "pass"

    waitsFor ->
      (promise != null) && (promise.inspect().state != 'pending')

    runs ->
      expect(promise).not.toBe(null)
      expect(promise.inspect().state).toBe('fulfilled')
