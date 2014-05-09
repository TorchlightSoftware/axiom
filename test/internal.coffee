should = require 'should'
_ = require 'lodash'
logger = require 'torch'

core = require '../lib/core'

mockRetriever = require './helpers/mockRetriever'

#loggers = [{writer: 'console', level: 'debug'}]
loggers = undefined

describe 'internal', ->
  beforeEach (done) ->
    core.reset(done)

  it 'reset should call system.kill', (done) ->
    called = false

    core.init {timeout: 20, loggers}, mockRetriever()
    core.respond 'system.kill', (args, doneKilling) ->
      called = true
      doneKilling()

    core.reset (err) ->
      should.not.exist err, 'expected no err'
      called.should.eql true
      done()

  it 'should delegate system.kill through link', (done) ->
    called = false

    core.init {timeout: 20, loggers}, mockRetriever()
    core.respond 'module.foo/stop', (args, doneKilling) ->
      called = true
      doneKilling()

    core.link 'system.kill', 'module.foo/stop'

    core.delegate "system.kill", {}, ->
      called.should.eql true
      done()
