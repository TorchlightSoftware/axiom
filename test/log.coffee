should = require 'should'

bus = require '../lib/bus'
core = require '..'

tests = [
  topic: 'debug'
  data: 'hello, debug'
 ,
  topic: 'error'
  data: 'hello, error'
 ,
  topic: 'info'
  data: 'hello, info'
]

# Helper to listen to topics on the Axiom logging
# channel without making any API calls to 'core'.
listen = (topic, callback) ->

  {channel} = core.log
  sub = bus.subscribe {channel, topic, callback}

  # Unsubscribe after being fired once
  sub.once()

# Test basic 'log' functionality
describe 'log', ->
  for test in tests
    do (test) ->

      it "should log on #{test.topic}", (done) ->

        # Given a listener on the 'log' channel and given topic
        listen test.topic, (data) ->

          # We should receive a log message
          should.exist data
          data.should.eql test.data

          done()

        # When we log it via the given topic
        core.log[test.topic] test.data

# Test 'info' coverage for public 'core' API
describe "log, 'core' API", ->
  beforeEach ->
    core.reset()

  loggedMethods = (m for m in Object.keys(core) when m isnt 'log')

  for method in loggedMethods
    do (method) ->
      it "should log calls to 'core.#{method}'", (done) ->

        # Given a listener on the 'info' topic of 'axiom.log'
        listen 'info', (data) ->

          # We should receive an informational message
          should.exist data
          data.should.eql "Calling 'core.#{method}'"

          done()

        # When we call the given public 'core' method
        try core[method]()
