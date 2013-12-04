should = require 'should'

bus = require '../lib/bus'
core = require '..'

logLevels = require '../lib/core/logLevels'

# Helper to listen to topics on the Axiom logging
# channel without making any API calls to 'core'.
listen = (topic, callback) ->

  {channel} = core.log
  sub = bus.subscribe {channel, topic, callback}

  # Unsubscribe after being fired once
  sub.once()

# Test basic 'log' functionality
describe 'log', ->
  after ->
    core.reset()

  for test in logLevels
    do (test) ->
      {topic, color} = test

      it "should log on #{topic}", (done) ->

        # Given a listener on the 'log' channel and given topic
        listen topic, (data) ->

          # We should receive a log message
          should.exist data
          data.should.eql color
          done()

        # When we log it via the given topic
        core.log[topic] color

methodTests = [
  method: 'init'
  args: ['config', 'retriever']
  expected: "Calling 'core.init' with args: { config: 'config', retriever: 'retriever' }"
 ,
  method: 'reset'
  args: []
  expected: "Calling 'core.reset'"
 ,
  method: 'load'
  args: ['moduleName']
  expected: "Calling 'core.load' with args: { moduleName: 'moduleName' }"
 ,
  method: 'request'
  args: ['channel', 'data']
  expected: "Calling 'core.request' with args: { channel: 'channel', data: 'data' }"
 ,
  method: 'delegate'
  args: ['channel', 'data']
  expected: "Calling 'core.delegate' with args: { channel: 'channel', data: 'data' }"
 ,
  method: 'respond'
  args: ['channel']
  expected: "Calling 'core.respond' with args: { channel: 'channel' }"
 ,
  method: 'send'
  args: ['channel', 'data']
  expected: "Calling 'core.send' with args: { channel: 'channel', data: 'data' }"
 ,
  method: 'listen'
  args: ['channel', 'topic']
  expected: "Calling 'core.listen' with args: { channel: 'channel', topic: 'topic' }"
]

# Test 'info' coverage for public 'core' API
describe "log, 'core' API", ->
  beforeEach ->
    core.reset()

  for test in methodTests
    do (test) ->
      {method, args, expected} = test

      it "should log calls to 'core.#{method}'", (done) ->

        # Given a listener on the 'info' topic of 'axiom.log'
        listen 'debug', (data) ->
          # We should receive an informational message
          should.exist data

          # With the expected details
          data.should.eql expected

          done()

        # When we call the given public 'core' method
        try core[method](args...)
