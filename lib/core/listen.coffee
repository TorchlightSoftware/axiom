bus = require '../bus'
log = require './log'

module.exports = (channel, topic, callback) ->
  log.info "Calling 'core.listen'"

  sub = bus.subscribe
    channel: channel
    topic: topic
    callback: (data, envelope) ->
      err = null
      callback err, envelope