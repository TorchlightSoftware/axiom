should = require 'should'
async = require 'async'
_ = require 'lodash'
logger = require 'torch'
{focus} = require 'qi'

mockery = require './mockery'
bus = require '../lib/bus'
core = require '../lib/core'


describe 'core.request', ->
  afterEach ->
    core.reset()
    mockery.disable()

  beforeEach (done) ->
    mockery.enable()

    core.init {timeout: 20}
    @moduleName = 'server'
    @serviceName = 'start'
    @channel = "#{@moduleName}.#{@serviceName}"
    @data =
      x: 2
      y: 'hello'

    done()

  it 'should receive exactly one valid response', (done) ->
    core.respond @channel, (message, done) ->
      done null, message

    core.request @channel, @data, (err, message) =>
      should.not.exist err

      should.exist message
      message.should.eql @data

      done()

  it 'should pass an error to the callback the response returns one', (done) ->
    testError = new Error 'testError'
    bus.subscribe
      channel: @channel
      topic: 'request.#'
      callback: (message, envelope) ->
        bus.publish
          channel: envelope.replyTo.channel
          topic: envelope.replyTo.topic.err
          data: testError

    core.request @channel, @data, (err, message) =>
      should.exist err
      should.not.exist message

      err.should.eql testError

      done()

  it 'should invoke the success callback exactly once, then discard all', (done) ->
    core.respond @channel, (message, finished) =>
      finished()

    test = (err, data) ->
      bus.publish
        channel: @channel
        topic: replyTo.topic.err
        data: new Error 'should not see'
      done()

    replyTo = core.request @channel, @data, test

  it 'should return a timeout error when it times out', (done) ->
    core.respond @channel, -> # I can't hear you
    core.request @channel, @data, (err, result) =>
      should.exist err
      err.message.should.eql "Request timed out on channel '#{@channel}'"
      should.not.exist result
      done()

  it 'should return immediately if there are no listeners', (done) ->
    core.request @channel, @data, (err, result) =>
      should.exist err
      expectedMsg = "No responders for request: '#{@channel}'"
      err.message.should.eql expectedMsg

      should.not.exist result

      done()


describe 'core.response', ->
  afterEach ->
    core.reset()

  beforeEach (done) ->
    mockery.enable()

    core.init()
    @channel = 'testChannel'
    @data =
      x: 2
      y: 'hello'
    done()

  it 'should send exactly one valid response', (done) ->
    echo = (message, next) -> next null, message
    core.respond @channel, echo

    bus.subscribe
      channel: @channel
      topic: "success.123"
      callback: (message) =>
        should.exist message
        message.should.eql @data
        done()

    bus.publish
      channel: @channel
      topic: "request.123"
      data: @data
      replyTo:
        channel: @channel
        topic:
          success: "success.123"


describe 'core.delegate', ->
  afterEach ->
    core.reset()

  beforeEach (done) ->
    mockery.enable()
    core.init {timeout: 20}
    done()

  it 'should should return if there are no responders', (done) ->
    channel = 'testChannel'

    core.delegate channel, {}, (err, results) ->
      should.not.exist err
      done()

  it 'responders on another channel should not interfere', (done) ->
    channel = 'testChannel'

    core.respond 'fooChannel', (message, next) ->
      next null, {helloFrom: 'fooChannel'}

    core.delegate channel, {}, (err, results) ->
      should.not.exist err
      done()

  it 'should should receive multiple responses', (done) ->
    channel = 'testChannel'

    core.respond channel, (message, next) ->
      next null, {helloFrom: 'responderA'}

    core.respond channel, (message, next) ->
      next null, {helloFrom: 'responderB'}

    core.delegate channel, {}, (err, results) ->
      should.not.exist err
      should.exist results

      values = _.values results
      should.exist values

      data = _.pluck values, 'data'
      should.exist data

      data.should.eql [
        { helloFrom: 'responderA' }
        { helloFrom: 'responderB' }
      ]

      done()

  it 'should return an err when a responder returns one', (done) ->
    channel = 'testChannel'

    testResponse = {message: 'this works'}
    core.respond channel, (message, next) ->
      next null, testResponse

    testError = new Error 'Expect this error'
    core.respond channel, (message, next) ->
      next testError, {}

    core.delegate channel, {}, (err, results) ->
      should.exist err
      expectedMsg = "Errors returned by responders on channel '#{channel}'"
      err.message.should.eql expectedMsg

      should.exist err.errors
      subErrors = (e.err for e in _.values err.errors)
      should.exist subErrors
      [subErr] = subErrors
      should.exist subErr
      subErr.should.eql testError

      should.exist results
      values = _.values results
      should.exist values
      [result] = values
      should.exist result
      result.data.should.eql testResponse

      done()

  it 'should return a timeout err when an implied request times out', (done) ->
    channel = 'testChannel'

    wontTimeOutMsg = {message: "I won't time out"}
    core.respond channel, (message, next) ->
      next null, wontTimeOutMsg

    # This WILL time out
    core.respond channel, (message, next) ->
      # next() will never get called.

    core.delegate channel, {}, (err, results) ->
      should.exist err
      expectedMsg = "Errors returned by responders on channel '#{channel}'"
      err.message.should.eql expectedMsg

      should.exist err.errors

      [responderId] = _.keys err.errors
      should.exist responderId

      subErr = err.errors[responderId]?.err
      should.exist subErr

      errMsg = "Responder with id #{responderId} timed out on channel '#{channel}'"
      subErr.message.should.eql errMsg

      should.exist results
      [result] = _.values results
      should.exist result
      should.exist result.data
      result.data.should.eql wontTimeOutMsg

      done()

describe 'core.listen', ->
  afterEach ->
    core.reset()
    mockery.disable()

  beforeEach (done) ->
    mockery.enable()

    core.init {timeout: 20}
    @channelA = 'testChannelA'
    @channelB = 'testChannelB'
    @dataA =
      x: 2
      y: 'hello'
    @dataB =
      x: 111
      y: 'goodbye'
    @topicA = 'info.A'
    @topicB = 'info.B'

    done()

  it 'should listen with a standard-signature callback', (done) ->
    core.listen @channelA, @topicA, (err, result) =>
      should.not.exist err
      should.exist result
      {data} = result
      should.exist data
      data.should.eql @dataA
      done()

    bus.publish
      channel: @channelA
      data: @dataA
      topic: @topicA

  it 'should listen to two topics on one channel', (done) ->
    cb = focus (err, results) =>
      should.not.exist err

      should.exist results

      [resultA, resultB] = results
      should.exist resultA
      should.exist resultB

      dataA = resultA.data
      should.exist dataA
      dataA.should.eql @dataA

      dataB = resultB.data
      should.exist dataB
      dataB.should.eql @dataB

      done()

    core.listen @channelA, @topicA, cb()

    core.listen @channelA, @topicB, cb()

    bus.publish
      channel: @channelA
      data: @dataA
      topic: @topicA

    bus.publish
      channel: @channelA
      data: @dataB
      topic: @topicB

  it 'should listen to two topics on two channels', (done) ->
    cb = focus (err, results) =>
      should.not.exist err

      should.exist results

      [resultA, resultB] = results
      should.exist resultA
      should.exist resultB

      dataA = resultA.data
      should.exist dataA
      dataA.should.eql @dataA

      dataB = resultB.data
      should.exist dataB
      dataB.should.eql @dataB

      done()

    core.listen @channelA, @topicA, cb()

    core.listen @channelB, @topicB, cb()

    bus.publish
      channel: @channelA
      data: @dataA
      topic: @topicA

    bus.publish
      channel: @channelB
      data: @dataB
      topic: @topicB

  it 'should listen to any topic on one channel', (done) ->
    core.listen @channelA, '#', (err, result) =>
      should.not.exist err
      should.exist result

      {data} = result
      should.exist data
      data.should.eql @dataA

      done()

    bus.publish
      channel: @channelA
      data: @dataA
      topic: @topicA
