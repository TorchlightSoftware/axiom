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
    bus.subscribe {
      channel: @channel
      topic: 'request.*'
      callback: (message, envelope) =>
        bus.publish {
          channel: envelope.replyTo.channel
          topic: envelope.replyTo.topic
          data: message
        }
    }

    core.request @channel, @data, (err, message) =>
      should.not.exist err

      should.exist message
      message.should.eql @data

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
      topic: "response.123"
      callback: (message) =>
        should.exist message
        message.should.eql @data

    bus.publish
      channel: @channel
      topic: "request.123"
      data: @data
      replyTo:
        channel: @channel
        topic: "response.123"

    done()
