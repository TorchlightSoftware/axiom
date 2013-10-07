should = require 'should'
mockery = require 'mockery'

core = require '../lib/core'
sample = require '../sample/sample'

describe 'core.init', ->
  after ->
    core.reset()

  afterEach ->
    core.reset()
    mockery.disable()

  beforeEach (done) ->
    mockery.enable
      warnOnReplace: false,
      warnOnUnregistered: false
    mockery.registerMock 'axiom-sample', sample
    done()

  it 'should dynamically load a module based on name', (done) ->
    config = {}
    moduleName = 'sample'
    modules = [moduleName]
    core.init config, modules

    channelName = 'sample.echo'
    data =
      greeting: 'hello!'
    core.request channelName, data, (err, result) ->
      should.not.exist err
      should.exist result
      result.should.eql data
      done()

  it 'should not init a module that is blacklisted', (done) ->
    @timeout 3000

    moduleName = 'sample'
    modules = [moduleName]
    config =
      blacklist: [moduleName]
    core.init config, modules

    channelName = 'sample.echo'
    data =
      greeting: 'hello!'
    core.request channelName, data, (err, result) ->
      should.exist err
      err.message.should.eql "Request timed out on channel 'sample.echo'"

      should.not.exist result

      done()
