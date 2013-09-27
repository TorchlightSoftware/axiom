should = require 'should'

bus = require '../lib/bus'
core = require '../lib/core'

describe 'core.request', ->
  afterEach ->
    bus.utils.reset()

  beforeEach (done) ->
    @channel = 'testChannel'
    @data =
      x: 2
      y: 'hello'
    done()

  it 'should receive exactly one valid response', (done) ->
    bus.subscribe
      channel: @channel
      topic: 'request.#'
      callback: (message, envelope) =>
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
      callback: (message, envelope) =>
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


describe 'core.response', ->
  beforeEach (done) ->
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
