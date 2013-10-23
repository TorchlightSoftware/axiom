should = require 'should'
mockery = require 'mockery'

core = require '../lib/core'
sample = require '../sample/sample'
{makeLoader} = require '../lib/util'

describe 'core.init', ->
  beforeEach ->
    @loader = makeLoader()

    mockery.enable
      warnOnReplace: false,
      warnOnUnregistered: false

    mockery.registerMock @loader.rel('node_modules', 'axiom-base'), {
      services:
        runtime: (args, next) ->
          next null, {message: 'axiom-base'}
    }
    prefix = @loader.rel 'node_modules', 'axiom-sample'
    mockery.registerMock @loader.rel('node_modules', 'axiom-sample'), sample

  afterEach ->
    core.reset()
    mockery.disable()

  after ->
    core.reset()

  it 'should load axiom-base', (done) ->
    core.init {}, {}, @loader

    core.request 'base.runtime', {}, (err, result) ->
      should.not.exist err
      should.exist result
      result.should.eql {message: 'axiom-base'}
      done()

  it 'should dynamically load a module based on name', (done) ->
    data = {greeting: 'hello!'}
    core.init {}, ['sample'], @loader

    core.request 'sample.echo', data, (err, result) ->
      should.not.exist err
      should.exist result
      result.should.eql data
      done()

  it 'should not init a module that is blacklisted', (done) ->
    core.init {blacklist: ['sample']}, ['sample'], @loader

    core.request 'sample.echo', {greeting: 'hello!'}, (err, result) ->
      should.exist err
      err.message.should.eql "No responders for request: 'sample.echo'"

      should.not.exist result

      done()
