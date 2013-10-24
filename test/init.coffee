path = require 'path'

should = require 'should'
mockery = require 'mockery'

core = require '../lib/core'
retriever = require '../lib/retriever'
util = require '../lib/util'

sample = require '../sample/sample'


testDir = __dirname
projDir = path.dirname testDir
sampleDir = path.join projDir, 'sample'
sampleProjDir = path.join sampleDir, 'project'


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

  it "should load a global 'Axiom' file from the project root", (done) ->
    axiomFile = require path.join(sampleProjDir, 'Axiom')
    should.exist axiomFile
    core.init {}, {}, @retriever
    core.config.should.eql axiomFile
    done()
