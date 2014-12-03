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
      extensions:
        sample: '*'
    core.init config, @retriever

    core.request 'sample.echo', data, (err, result) ->
      should.not.exist err
      should.exist result
      result.should.eql data
      done()

  it "should load the project export as a config", (done) ->
    internal = require '../lib/core/internal'
    projectConfig = require proj1Dir
    should.exist projectConfig
    core.init {}, @retriever
    internal.config.should.containEql projectConfig
    done()

  it "should load a config override from the config folder", (done) ->
    core.init {extensions: {sample: '*'}}, @retriever

    sampleExtension = require path.join(proj1Dir, 'node_modules/axiom-sample')

    # Given an extension with a service and corresponding config entry
    defaultSampleConfig = sampleExtension.config
    should.exist defaultSampleConfig

    # And a config override in the local project
    overrideConfig = require path.join(proj1Dir, 'config/sample')
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

          # Then the mock retriever should be included in the context
          @root.should.eql 'domain/server'
          (typeof @rel).should.eql 'function'
          (typeof @retrieve).should.eql 'function'

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

  it "should link two channels", (done) ->

    config =
      extensions:

        greeting:
          services:
            hello: (args, done) ->
              done null, {message: 'Hello, world!'}

      routes: [
        ['link', 'outside.hello', 'greeting.hello']
      ]

    core.init config, @retriever

    core.request 'outside.hello', {}, (err, result) ->
      should.not.exist err
      should.exist result
      result.should.eql {message: 'Hello, world!'}
      done()
