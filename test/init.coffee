path = require 'path'

should = require 'should'
mockery = require 'mockery'
_ = require 'lodash'
logger = require 'torch'

core = require '../lib/core'
findProjectRoot = require '../lib/findProjectRoot'

testDir = __dirname
projDir = path.dirname testDir
sampleDir = path.join projDir, 'sample'
sampleProjDir = path.join sampleDir, 'project'

sample = require path.join(sampleDir, 'sample')


describe 'core.init', ->
  beforeEach ->
    process.chdir sampleProjDir

    @retriever = _.clone require '../lib/retriever'
    @retriever.projectRoot = findProjectRoot(process.cwd())

    mockery.enable
      warnOnReplace: false,
      warnOnUnregistered: false

    mockery.registerMock @retriever.rel('node_modules', 'axiom-base'), {
      services:
        runtime: (args, next) ->
          next null, {message: 'axiom-base'}
    }
    prefix = @retriever.rel 'node_modules', 'axiom-sample'
    mockery.registerMock @retriever.rel('node_modules', 'axiom-sample'), sample

  afterEach ->
    core.reset()
    mockery.disable()

  after ->
    core.reset()

  it 'should load axiom-base', (done) ->
    core.init()

    core.request 'base.runtime', {}, (err, result) ->
      should.not.exist err
      should.exist result
      result.should.eql {message: 'axiom-base'}
      done()

  it 'should dynamically load a module based on name', (done) ->
    data = {greeting: 'hello!'}
    core.init {}, ['sample']

    core.request 'sample.echo', data, (err, result) ->
      should.not.exist err
      should.exist result
      result.should.eql data
      done()

  it 'should not init a module that is blacklisted', (done) ->
    core.init {blacklist: ['sample']}, ['sample']

    core.request 'sample.echo', {greeting: 'hello!'}, (err, result) ->
      should.exist err
      err.message.should.eql "No responders for request: 'sample.echo'"

      should.not.exist result

      done()

  it "should load a global 'axiom' file from the project root", (done) ->
    axiomFile = require path.join(sampleProjDir, 'axiom')
    should.exist axiomFile
    core.init {}, {}, @retriever
    core.config.should.eql axiomFile
    done()

  it "should assume an 'axiom' folder containing config overrides", (done) ->
    core.init {}, ['sample'], @retriever

    # Given an extension with a service and corresponding config entry
    defaultSampleConfig = sample.config.whatsMyContext
    should.exist defaultSampleConfig

    # And a config override in the local project
    overrideConfigPath = path.join sampleProjDir, 'axiom', 'sample'
    overrideConfig = require(overrideConfigPath).whatsMyContext
    should.exist overrideConfig

    expectedConfig = _.merge {}, defaultSampleConfig, overrideConfig

    # When the service is called
    core.request 'sample.whatsMyContext', {}, (err, config) ->
      should.not.exist err

      # Then the resulting @config should be the default merged with the override
      should.exist config
      config.should.eql expectedConfig

      done()

  it "'retriever' in 'util' should be default instance", (done) ->
    defaultRetriever = @retriever

    # Given a service
    server =
      services:
        "run/prepare": (args, fin) ->

          # Then the retriever should include the default 'retriever'
          should.exist @util
          @util.should.include defaultRetriever
          fin()

    # When core is initialized without injecting a 'retriever'
    core.init()
    core.load "server", server

    # And the service is called
    core.request "server.run/prepare", {}, (err, result) ->
      should.not.exist err
      done()

  it "should expose an injected 'retriever' in 'util'", (done) ->
    defaultRetriever = @retriever

    # Given a mock test 'retriever'
    mockRetriever =
      retrieve: (name...) -> {}
      retrieveExtension: (name...) -> {}

    # And a test service
    server =
      services:
        "run/prepare": (args, fin) ->
          should.exist @util

          # Then @util should include the mock retriever
          @util.should.include mockRetriever

          # And not the default retriever
          @util.should.not.include defaultRetriever

          fin()

    # When core is initialized with the mock retriever
    core.init {}, {}, mockRetriever

    # And the service is loaded
    core.load "server", server

    # And the service is called
    core.request "server.run/prepare", {}, (err, result) ->

      # It should return without its assertions failing
      should.not.exist err
      done()
