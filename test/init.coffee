should = require 'should'
mockery = require 'mockery'

core = require '../lib/core'
sample = require '../sample/sample'

describe 'core.init', ->
  after ->
    core.config.modules = []

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
    moduleName = 'sample'
    config =
      modules: [moduleName]
    core.init config

    channelName = 'sample.echo'
    data =
      greeting: 'hello!'
    core.request channelName, data, (err, result) ->
      should.not.exist err
      should.exist result
      result.should.eql data
      done()
