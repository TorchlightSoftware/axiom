should = require 'should'
logger = require 'torch'

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
  beforeEach (done) ->
    core.reset(done)

  for test in logLevels
    do (test) ->
      {topic, color} = test

      it "should log on #{topic}", (done) ->

        # Given a listener on the 'log' channel and given topic
        listen topic, (data) ->

          # We should receive a log message
          should.exist data
          data.should.eql [color]
          done()

        # When we log it via the given topic
        core.log[topic] color

methodTests = [
  method: 'init'
  args: ['config', 'retriever']
  expected: "Calling 'core.init' with args:"
 ,
  method: 'load'
  args: ['extensionName']
  expected: "Calling 'core.load' with args:"
 ,
  method: 'request'
  args: ['channel', 'data', ->]
  expected: "Calling 'core.request' with args:"

 ,
  method: 'delegate'
  args: ['channel', 'data']
  expected: "Calling 'core.delegate' with args:"
 ,
  method: 'respond'
  args: ['channel', ->]
  expected: "Calling 'core.respond' with args:"
 ,
  method: 'send'
  args: ['channel', 'data']
  expected: "Calling 'core.send' with args:"
 ,
  method: 'listen'
  args: ['channel', 'topic']
  expected: "Calling 'core.listen' with args:"
]

# Test 'info' coverage for public 'core' API
describe "log, 'core' API", ->
  beforeEach (done) ->
    core.reset(done)

  for test in methodTests
    do (test) ->
      {method, args, expected} = test

      it "should log calls to 'core.#{method}'", (done) ->

        # Given a listener on the 'info' topic of 'axiom.log'
        listen 'debug', ([data]) ->
          # We should receive an informational message
          should.exist data

          # With the expected details
          data.should.containEql expected

          done()

        # When we call the given public 'core' method
        core[method] args...
