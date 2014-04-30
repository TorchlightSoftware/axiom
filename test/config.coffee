should = require 'should'
_ = require 'lodash'
logger = require 'torch'
{join} = require 'path'

core = require '../lib/core'
mockRetriever = require './helpers/mockRetriever'

initCoreWithMock = (packages) ->
  retriever = mockRetriever()
  _.merge retriever.packages, packages
  core.init {
    timeout: 20
  }, retriever

describe 'extension config', ->

  beforeEach ->
    core.wireUpLoggers [{writer: 'console', level: 'info'}]

  afterEach ->
    core.reset()

  it 'should receive general config', (done) ->

    # Given an Axiom config with a 'general' section defined
    axiomConfig =
      general:
        serverPort: 4000
        apiPort: 4001

    # And an extension config as a function of the app config
    extensionConfig = (general) ->

      # It should return without its assertions failing
      should.exist general
      general.should.eql axiomConfig.general
      done()
      return general

    # When core is initialized
    initCoreWithMock {
      package:
        dependencies:
          'axiom-server': '*'
      node_modules:
        'axiom-server': {}
      axiom: axiomConfig
      axiom_configs:
        server: extensionConfig
      #node_modules:
        #'axiom-server': {}
    }

  it 'should be accessible within an extension', (done) ->
    serverExtension =
      config:
        port: 4000

      services:
        run: (args, fin) ->
          4000.should.eql @config.port
          fin()

    core.load 'server', serverExtension
    core.request 'server.run', {}, done

  it 'should not be accessible from another extension', (done) ->
    irrelevantExtension =
      config:
        irrelevantValue: 2

    serverExtension =
      services:
        run: (args, fin) ->
          @config.should.not.have.key 'irrelevantValue'
          fin()

    core.load 'irrelevant', irrelevantExtension
    core.load 'server', serverExtension
    core.request 'server.run', {}, done
