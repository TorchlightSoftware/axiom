should = require 'should'

bus = require '../lib/bus'
log = require '../lib/core/log'

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
  {channel} = log
  bus.subscribe {channel, topic, callback}

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
        log[test.topic] test.data
