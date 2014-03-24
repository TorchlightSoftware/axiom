should = require 'should'
_ = require 'lodash'
logger = require 'torch'
{join} = require 'path'

core = require '../lib/core'
mockRetriever = require './helpers/mockRetriever'

initCore = (packages) ->
  retriever = mockRetriever()
  _.merge retriever.packages, packages
  core.init {timeout: 20}, retriever

describe 'application config', ->

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
    initCore {
      axiom: axiomConfig
      node_modules:
        'axiom-server':
          services:
            run: runService
    }

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
    initCore {
      axiom: axiomConfig
      node_modules:
        'axiom-server':
          services:
            run: runService
    }

    # And the service is called
    core.request 'server.run', {}, (err, result) ->

      # It should return without its assertions failing
      should.not.exist err
      done()

  it 'should expose app config to a base script', (done) ->

    # Given an Axiom config with an 'app' section defined
    axiomConfig =
      app:
        serverPort: 4000
        apiPort: 4001

    # And a run service that inherits from a base
    baseService = (args, next) ->
      should.exist @app
      @app.should.eql axiomConfig.app
      next()

    # When core is initialized
    initCore {
      axiom: axiomConfig
      node_modules:
        'axiom-server':
          config:
            run:
              base: 'runtime'
        'axiom-base':
          {
            services:
              runtime: baseService
          }
    }

    # And the service is called
    core.request 'server.run', {}, (err, result) ->

      # It should return without its assertions failing
      should.not.exist err
      done()

  it 'should expose app config to module configs', (done) ->

    # Given an Axiom config with an 'app' section defined
    axiomConfig =
      app:
        serverPort: 4000
        apiPort: 4001

    # And a module config as a function of the app config
    moduleConfig = (app) ->

      # It should return without its assertions failing
      should.exist app
      app.should.eql axiomConfig.app
      done()
      return app

    # When core is initialized
    initCore {
      axiom: axiomConfig
      axiom_configs:
        server: moduleConfig
    }

  it 'should load an object based module config', (done) ->

    # Given a module config
    moduleConfig = {run: {foo: 'yes'}}

    # And a run service
    runService = (args, fin) ->
      should.exist @config
      @config.should.eql moduleConfig.run
      fin()

    # When core is initialized
    initCore {
      axiom_configs:
        server: moduleConfig
      node_modules:
        'axiom-server':
          services:
            run: runService
    }

    # And the service is called
    core.request 'server.run', {}, (err, result) ->

      # It should return without its assertions failing
      should.not.exist err
      done()
