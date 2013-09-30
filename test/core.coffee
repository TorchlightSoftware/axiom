should = require 'should'
async = require 'async'

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

  it 'should return a timeout result when it times out', (done) ->
    @timeout 3000

    core.request @channel, @data, (err, result) =>
      should.not.exist err

      should.exist result
      expected =
        message: 'Request timed out'
        timeout: 2000
        channel: @channel
        data: @data
      result.should.eql expected

      done()


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

describe 'core.delegate', ->
  beforeEach (done) ->
    done()

  it 'should return results when everything works', (done) ->
    channels = ['channelA', 'channelB', 'channelC']

    expected = [
      { helloFrom: 'channelA' },
      { helloFrom: 'channelB' },
      { helloFrom: 'channelC' }
    ]

    channels.map (ch) ->
      core.respond ch, (message, next) ->
        next null, {helloFrom: ch}

    core.delegate channels, {}, (err, result) ->
      should.not.exist err
      should.exist result
      result.should.eql expected
      done()

  it 'should return an err when a responder returns one', (done) ->
    channels = ['willWork', 'wontWork']

    testResponse = {message: 'this works'}
    core.respond 'willWork', (message, next) ->
      next null, testResponse

    testError = new Error 'Expect this error'
    core.respond 'wontWork', (message, next) ->
      next testError, {}

    core.delegate channels, {}, (err, result) ->
      should.exist err
      err.should.eql testError

      should.exist result
      should.exist result.length
      result.length.should.eql 2

      should.exist result[0]
      result[0].should.eql testResponse

      should.not.exist result[1]

      done()

  it 'should receive a timeout result when an implied request out', (done) ->
    @timeout 3000

    channels = ['wontTimeOut', 'willTimeOut']
    core.init()

    wontTimeOutMsg = {message: "I won't time out"}
    core.respond 'wontTimeOut', (message, next) ->
      next null, wontTimeOutMsg

    core.delegate channels, {}, (err, result) ->
      should.not.exist err

      should.exist result
      result.length.should.eql 2

      should.exist result[0]
      result[0].should.eql wontTimeOutMsg

      should.exist result[1]
      result[1].should.eql {
        message: 'Request timed out'
        timeout: 2000
        channel: 'willTimeOut'
        data: {}
      }

      done()
