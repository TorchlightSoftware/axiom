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

  beforeEach (done) ->
    core.reset (err) ->
      core.wireUpLoggers [{writer: 'console', level: 'info'}]
      done(err)

  it 'should receive project config', (done) ->

    # Given a project config with a 'config' section defined
    projectConfig =
      extensions:
        server: '*'
      config:
        serverPort: 4000
        apiPort: 4001

    # And an extension config as a function of the app config
    extensionConfig = (app) ->

      # It should return without its assertions failing
      should.exist app
      app.should.eql projectConfig.config
      done()
      return app

    # When core is initialized
    initCoreWithMock {
      '': projectConfig
      node_modules:
        'axiom-server': {}
      config:
        server: extensionConfig
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
