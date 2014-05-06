path = require 'path'
should = require 'should'
_ = require 'lodash'
logger = require 'torch'

core = require '../lib/core'

proj1Dir = path.join __dirname, '../sample/project1'

describe 'core.init', ->
  before ->
    @retriever =
      root: proj1Dir

  beforeEach (done) ->
    core.reset(done)

  it 'should dynamically load a module based on name', (done) ->
    data = {greeting: 'hello!'}
    config =
      modules: ['sample']
    core.init config, @retriever

    core.request 'sample.echo', data, (err, result) ->
      should.not.exist err
      should.exist result
      result.should.eql data
      done()

  it 'should not init a module that is blacklisted', (done) ->
    config =
      blacklist: ['sample']
      modules: ['sample']
    core.init config, @retriever

    core.request 'sample.echo', {greeting: 'hello!'}, (err, result) ->
      should.exist err
      err.message.should.eql "No responders for request: 'sample.echo'"

      should.not.exist result

      done()

  it "should load a global 'axiom' file from the project root", (done) ->
    internal = require '../lib/core/internal'
    axiomFile = require path.join(proj1Dir, 'axiom')
    should.exist axiomFile
    core.init {}, @retriever
    internal.config.should.include axiomFile
    done()

  it "should load a config override from the axiom_configs folder", (done) ->
    core.init {modules: ['sample']}, @retriever

    sampleExtension = require path.join(proj1Dir, 'node_modules/axiom-sample')

    # Given an extension with a service and corresponding config entry
    defaultSampleConfig = sampleExtension.config
    should.exist defaultSampleConfig

    # And a config override in the local project
    overrideConfig = require path.join(proj1Dir, 'axiom_configs/sample')
    should.exist overrideConfig

    expectedConfig = _.merge {}, defaultSampleConfig, overrideConfig

    # When the service is called
    core.request 'sample.whatsMyContext', {}, (err, config) ->
      should.not.exist err

      # Then the resulting @config should be the default merged with the override
      should.exist config
      config.should.eql expectedConfig

      done()

  it "should expose an injected 'retriever'", (done) ->
    defaultRetriever = @retriever

    # Given a mock test 'retriever'
    mockRetriever =
      root: ''
      retrieve: (name...) -> {}
      retrieveExtension: (name...) -> {}

    # And a test service
    server =
      services:
        "run/prepare": (args, fin) ->
          should.exist @retriever

          # Then @retriever should include the mock retriever
          @retriever.root.should.eql 'server'

          @retriever.should.have.keys ['root', 'rel', 'retrieve']
          @retriever.should.not.have.keys ['retrieveExtension']

          fin()

    # When core is initialized with the mock retriever
    core.init {}, mockRetriever

    # And the service is loaded
    core.load "server", server

    # And the service is called
    core.request "server.run/prepare", {}, (err, result) ->

      # It should return without its assertions failing
      should.not.exist err
      done()

  it "should load an appExtension", (done) ->
    config =
      appExtensions:
        doStuff: 'appExtensions/doStuff'

    core.init config, @retriever
    core.request 'doStuff.doStuff', {}, (err, result) ->
      result.should.eql {status: 'stuff is done'}
      done()
