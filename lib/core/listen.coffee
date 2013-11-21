bus = require '../bus'

module.exports = (channel, topic, callback) ->
  core = require '../core'
  core.log.coreEntry 'listen', {channel, topic}

  sub = bus.subscribe
    channel: channel
    topic: topic
    callback: (data, envelope) ->
      err = null
      callback err, envelope
