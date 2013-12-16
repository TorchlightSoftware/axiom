should = require 'should'
async = require 'async'
_ = require 'lodash'
logger = require 'torch'
{focus} = require 'qi'
{join} = require 'path'

bus = require '../lib/bus'
core = require '../lib/core'

mockRetriever = require './helpers/mockRetriever'

initCore = (axiomConfig, runService) ->
  retriever = mockRetriever()
  retriever.packages.axiom = axiomConfig
  retriever.packages.node_modules['axiom-server'] =
    services:
      run: runService

  core.init {timeout: 20}, retriever

describe 'core.request', ->

  afterEach ->
    core.reset()

  it 'should expose the app config in a service', (done) ->

    # Given an Axiom config with an 'app' section defined
    axiomConfig =
      app:
        serverPort: 4000
        apiPort: 4001

    # And a run service
    runService = (args, fin) ->
      should.exist @app
      @app.should.eql axiomConfig.app
      fin()

    # When core is initialized
    initCore axiomConfig, runService

    # And the service is called
    core.request 'server.run', {}, (err, result) ->

      # It should return without its assertions failing
      should.not.exist err
      done()

  it 'should expose an empty object for the app config', (done) ->

    # Given an Axiom config with an 'app' section defined
    axiomConfig = {}

    # And a run service
    runService = (args, fin) ->
      should.exist @app
      @app.should.eql {}
      fin()

    # When core is initialized
    initCore axiomConfig, runService

    # And the service is called
    core.request 'server.run', {}, (err, result) ->

      # It should return without its assertions failing
      should.not.exist err
      done()
