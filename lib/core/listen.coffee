bus = require '../bus'

module.exports = (channel, topic, callback) ->
  core = require '../core'

  core.log.info "Calling 'core.listen'"

  sub = bus.subscribe
    channel: channel
    topic: topic
    callback: (data, envelope) ->
      err = null
      callback err, envelope