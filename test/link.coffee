should = require 'should'
logger = require 'torch'
mockRetriever = require './helpers/mockRetriever'

core = require '..'

describe 'core.link', ->
  beforeEach (done) ->
    core.reset (err) ->
      core.init {}, mockRetriever()
      core.wireUpLoggers [{writer: 'console', level: 'info'}]
      done(err)

  it 'should forward a delegation', (done) ->

    {responderId} = core.respond 'greet', (args, done) ->
      done null, {greeting: 'hello'}

    core.link 'salutation', 'greet'

    core.delegate 'salutation', {}, (err, data) ->
      should.not.exist err
      should.exist data?[responderId], 'expected data for responderId'
      data[responderId].should.eql {greeting: 'hello'}

      done()

  it 'should forward a request', (done) ->

    {responderId} = core.respond 'greet', (args, done) ->
      done null, {greeting: 'hello'}

    core.link 'salutation', 'greet'

    core.request 'salutation', {}, (err, data) ->
      should.not.exist err
      should.exist data, 'expected response data'
      data.should.eql {greeting: 'hello'}

      done()

  it "should forward a namespace", (done) ->

    {responderId} = core.respond 'sample.greet', (args, done) ->
      done null, {greeting: 'hello'}

    core.link 'salutation', 'sample'

    core.request 'salutation.greet', {}, (err, result) ->
      should.not.exist err
      should.exist result
      result.should.eql {greeting: 'hello'}
      done()

  it "should forward to a base namespace", (done) ->

    {responderId} = core.respond 'sample.greet', (args, done) ->
      done null, {greeting: 'hello'}

    core.link 'salutation.messages', 'sample'

    core.request 'salutation.messages/greet', {}, (err, result) ->
      should.not.exist err
      should.exist result
      result.should.eql {greeting: 'hello'}
      done()
