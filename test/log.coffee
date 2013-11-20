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

# Test 'info' coverage for public 'core' API
describe "log, 'core' API", ->
  beforeEach ->
    core.reset()

  loggedMethods = Object.keys(core).filter (m) -> m isnt 'log'

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
