path = require 'path'

should = require 'should'
mockery = require 'mockery'
_ = require 'lodash'
logger = require 'torch'

core = require '../lib/core'
findProjectRoot = require '../lib/findProjectRoot'

sampleDir = path.join __dirname, '../sample'
sampleProjDir = path.join sampleDir, 'project3'
sample = require path.join sampleDir, 'sample'

describe 'config.app', ->
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

  it 'should expose the application-wide config in extension service contexts when it exists', (done) ->
    # Given an Axiom config
    axiomConfig = require path.join(process.cwd(), 'axiom')
    should.exist axiomConfig

    # With an 'app' section defined
    should.exist axiomConfig.app

    # And a test service
    server =
      services:
        run: (args, fin) ->

          should.exist @app
          @app.should.eql axiomConfig.app

          fin()

    # When core is initialized
    core.init()

    # And the service is loaded
    core.load 'server', server

    # And the service is called
    core.request 'server.run', {}, (err, result) ->

      # It should return without its assertions failing
      should.not.exist err
      done()
