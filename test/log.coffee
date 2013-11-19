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

describe 'log', ->
  for test in tests
    do (test) ->
      it "should log on #{test.topic}", (done) ->

        # Given a listener on the 'log' channel and given topic
        bus.subscribe
          channel: log.channel
          topic: test.topic
          callback: (data, envelope) ->

            # We should receive a log message
            should.exist data
            data.should.eql test.data
            done()

        # When we log it via the given topic
        log[test.topic] test.data
