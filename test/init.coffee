path = require 'path'

should = require 'should'
mockery = require 'mockery'
_ = require 'lodash'

core = require '../lib/core'
retriever = require '../lib/retriever'
util = require '../lib/util'


testDir = __dirname
projDir = path.dirname testDir
sampleDir = path.join projDir, 'sample'
sampleProjDir = path.join sampleDir, 'project'

sample = require path.join(sampleDir, 'sample')


describe 'core.init', ->
  beforeEach ->
    process.chdir sampleProjDir

    @retriever = require '../lib/retriever'
    @retriever.projRoot = util.findProjRoot()

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

    # Given an extension ('sample') with a default config for a namespace
    # of a service ('whatsMyContext') which returns its '@config'
    defaultSampleConfig = sample.config.whatsMyContext
    should.exist defaultSampleConfig

    # And an override config for the overall extension ('sample')
    # within an 'axiom' folder in the project root
    overrideConfigPath = path.join sampleProjDir, 'axiom', 'sample'

    # And the specific config subsection for the namespace of interest
    overrideConfig = require(overrideConfigPath).whatsMyContext
    should.exist overrideConfig

    # And an overall expectation of what the overall namespace config
    # should look like once the defaults have been overridden
    expectedConfig = _.merge {}, defaultSampleConfig, overrideConfig

    # When the service is called
    core.request 'sample.whatsMyContext', {}, (err, result) ->
      should.not.exist err

      # Given that it has returned the result, which is simply the
      # value of '@config' within the service's context
      should.exist result

      # The result ('@config') should be equal to the default namespace
      # config, with the overrides merged over it.
      result.should.eql expectedConfig

      done()
