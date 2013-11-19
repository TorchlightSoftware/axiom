bus = require '../bus'

channel = 'axiom.log'

log = (topic) -> (data) ->
  bus.publish {channel, topic, data}

module.exports =
  channel: channel
  debug: log 'debug'
  error: log 'error'
  info: log 'info'
