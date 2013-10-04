should = require 'should'
async = require 'async'
_ = require 'lodash'
logger = require 'torch'

bus = require '../lib/bus'
core = require '../lib/core'

describe 'core.request', ->
  afterEach ->
    bus.utils.reset()

  beforeEach (done) ->
    core.init {timeout: 20}
    @channel = 'testChannel'
    @data =
      x: 2
      y: 'hello'
    done()

  it 'should receive exactly one valid response', (done) ->
    bus.subscribe
      channel: @channel
      topic: 'request.#'
      callback: (message, envelope) ->
        bus.publish
          channel: envelope.replyTo.channel
          topic: envelope.replyTo.topic.success
          data: message

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
    unsubbedErr = unsubbedSuccess = false
    callback = (message, envelope) =>
      {replyTo} = envelope
      tap = bus.addWireTap (d, e) ->
        {err, success} = replyTo.topic
        {topic} = e.data
        if e.topic is 'subscription.removed'
          unsubbedErr ||= topic is err
          unsubbedSuccess ||= topic is success

        if unsubbedErr and unsubbedSuccess
          tap()
          done()

      bus.publish
        channel: replyTo.channel
        topic: replyTo.topic.success
        data: {}

    sub = bus.subscribe
      channel: @channel
      topic: 'request.#'
      callback: callback

    noop = ->
    core.request @channel, @data, noop

  it 'should return a timeout error when it times out', (done) ->
    @timeout 3000

    core.request @channel, @data, (err, result) =>
      should.exist err
      expectedMsg = "Request timed out on channel '#{@channel}'"
      err.message.should.eql expectedMsg

      should.not.exist result

      done()


describe 'core.response', ->
  afterEach ->
    bus.utils.reset()

  beforeEach (done) ->
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
    bus.utils.reset()

  beforeEach (done) ->
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
