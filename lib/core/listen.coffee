bus = require '../bus'

module.exports = (channel, topic, callback) ->
  sub = bus.subscribe
    channel: channel
    topic: topic
    callback: (data, envelope) ->
      err = null
      callback err, envelope