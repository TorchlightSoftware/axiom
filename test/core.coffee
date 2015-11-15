should = require 'should'
_ = require 'lodash'
{focus} = require 'qi'
{join} = require 'path'

bus = require '../lib/bus'
core = require '../lib/core'

mockRetriever = require './helpers/mockRetriever'

describe 'core.request', ->
  beforeEach (done) ->
    core.reset =>

      core.init {timeout: 20}, mockRetriever()
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

  it 'should pass an error to the callback', (done) ->
    testError = new Error 'testError'
    core.respond @channel, (args, fin) ->
      fin testError

    core.request @channel, @data, (err, message) =>
      should.exist err
      should.exist message
      message.should.eql {}

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
    {RequestTimeoutError} = require '../lib/errorTypes'
    core.respond @channel, -> # I can't hear you
    core.request @channel, @data, (err, result) =>
      should.exist err
      err.message.should.eql "Request timed out after 20ms on channel: '#{@channel}'"
      err.should.be.instanceOf RequestTimeoutError
      should.exist result
      result.should.eql {}
      done()

  it 'should return immediately if there are no listeners', (done) ->
    core.request @channel, @data, (err, result) =>
      should.exist err
      expectedMsg = "No responders for request: '#{@channel}'"
      err.message.should.eql expectedMsg

      should.exist result
      result.should.eql {}
      done()

  it 'should return an "ambiguous" error when there are multiple responders', (done) ->
    core.respond @channel, ->
    core.respond @channel, ->
    core.request @channel, @data, (err, result) =>
      should.exist err
      err.message.should.eql "Ambiguous: 2 responders for request: '#{@channel}'"
      should.exist result
      result.should.eql {}
      done()

  describe 'namespace helper', ->
    it 'should shortcut to module', (done) ->
      core.respond 'server.run', (message, done) ->
        done null, message

      serverReq = core.request.ns 'server'
      serverReq 'run', @data, (err, message) =>
        should.not.exist err

        should.exist message
        message.should.eql @data

        done()

    it 'should shortcut to sub-service', (done) ->
      core.respond 'server.run/load', (message, done) ->
        done null, message

      serverReq = core.request.ns 'server.run'
      serverReq 'load', @data, (err, message) =>
        should.not.exist err

        should.exist message
        message.should.eql @data

        done()

describe 'core.response', ->
  beforeEach (done) ->
    core.reset =>
      core.init {timeout: 20}, mockRetriever()
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
    core.reset =>
      core.init {
        timeout: 20
        #loggers: [{writer: 'console', level: 'debug'}]
      }, mockRetriever()
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

    sub = core.respond channel, (message, next) ->
      next null, {helloFrom: 'responderA'}

    res1 = sub.responderId

    sub = core.respond channel, (message, next) ->
      next null, {helloFrom: 'responderB'}

    res2 = sub.responderId

    core.delegate channel, {}, (err, results) ->
      should.not.exist err
      should.exist results

      results[res1].should.eql { helloFrom: 'responderA' }
      results[res2].should.eql { helloFrom: 'responderB' }
      done()

  it 'should return an err when a responder returns one', (done) ->
    @timeout 400 # wow, it takes 363ms to format a stack trace

    channel = 'testChannel'

    # Given a success response
    testResponse = {message: 'this works'}
    core.respond channel, (message, next) ->
      next null, testResponse

    # And an error response
    testError = new Error 'Expect this error'
    core.respond channel, (message, next) ->
      next testError, {}

    # When I delegate to the channel
    core.delegate channel, {}, (err, results) ->

      # Then I should receive an error
      should.exist err
      expectedMsg = "Received errors from channel '#{channel}':\nError: #{testError.message}"
      err.message.should.startWith expectedMsg

      should.exist err.errors, 'expected errors'
      subErrors = _.values err.errors
      should.exist subErrors, 'expected subErrors'
      [subErr] = subErrors
      should.exist subErr, 'expected subErr'
      subErr.should.eql testError

      should.exist results, 'expected results'
      values = _.values results
      should.exist values, 'expected values'
      [result] = values
      should.exist result, 'expected result'
      result.should.eql testResponse

      done()

  it 'should return a timeout err when an implied request times out', (done) ->
    channel = 'testChannel'

    wontTimeOutMsg = {message: "I won't time out"}
    sub = core.respond channel, (message, next) ->
      next null, wontTimeOutMsg

    successId = sub.responderId

    # This WILL time out
    sub = core.respond channel, (message, next) ->
      # next() will never get called.

    errId = sub.responderId

    core.delegate channel, {}, (err, results) ->
      should.exist err

      expectedMsg = "Received errors from channel '#{channel}':\nAxiomError/RequestTimeoutError: Responder with id '#{errId}' timed out after 20ms on channel: '#{channel}'"
      err.message.should.startWith expectedMsg

      should.exist err.errors

      subErr = err.errors[errId]
      should.exist subErr, 'expected subErr'

      errMsg = "Responder with id '#{errId}' timed out after 20ms on channel: '#{channel}'"
      subErr.message.should.eql errMsg

      should.exist results
      result = results[successId]
      should.exist result
      result.should.eql wontTimeOutMsg

      done()

  it 'should collect args', (done) ->

    # Given a pitch function
    pitch = (args, fin) ->
      fin null, {foo: 1}
    pitch.extension = 'sandbox'

    # And I attach the endpoints
    responderId = core.respond 'pitch', pitch

    # When I delegate
    core.delegate 'pitch', {input: 2}, (err, result) ->
      should.not.exist err
      should.exist result?.sandbox, 'expected responder data'
      should.exist result.__delegation_result, 'expected __delegation_result'
      result.__delegation_result.should.eql true
      should.exist result.__input, 'expected __input'
      result.__input.should.eql {input: 2}
      result.sandbox.should.eql {input: 2, foo: 1}
      done()

  it 'should collect errors', (done) ->

    # Given an error service
    error = (args, fin) ->
      fin(new Error 'oops')
    error.extension = 'sandbox'

    # And I attach the endpoints
    responderId = core.respond 'error', error

    # When I delegate
    core.delegate 'error', {something: 1}, (err, result) ->
      should.exist err?.errors?.sandbox, 'expected err for responder'
      should.exist result, 'expected result'
      result.should.eql
        __delegation_result: true
        __input: {something: 1}
      done()

  it 'should distribute args', (done) ->

    # Given a sandbox extension
    responderId = core.load 'sandbox',
      services:
        pitch: (args, fin) ->
          args.should.eql {bar: 2, foo: 1}
          fin null, args

    args =
      __delegation_result: true
      __input: {bar: 2}
      sandbox: {foo: 1}
      other: {value: "shouldn't see"}

    # When I delegate
    core.delegate 'sandbox.pitch', args, (err, result) ->
      should.not.exist err
      should.exist result?.sandbox, 'expected responder data'
      result.sandbox.should.eql {bar: 2, foo: 1}
      done()

  it 'should use input args', (done) ->

    # Given a sandbox extension
    responderId = core.load 'sandbox',
      services:
        pitch: (args, fin) ->
          args.should.eql {bar: 2}
          fin null, args

    args =
      __delegation_result: true
      __input: {bar: 2}
      other: {value: "shouldn't see"}

    # When I delegate
    core.delegate 'sandbox.pitch', args, (err, result) ->
      should.not.exist err
      should.exist result?.sandbox, 'expected responder data'
      result.sandbox.should.eql {bar: 2}
      done()

describe 'core.listen', ->
  beforeEach (done) ->
    core.reset =>
      core.init {timeout: 20}, mockRetriever()
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
