module.exports = (channel, service) ->
  core = require '../core'
  core.log.coreEntry 'respondOnce', {channel}

  sub = core.respond channel, (args, done) ->
    core.log.debug 'detaching responder from:', {channel}
    sub.unsubscribe()
    service(args, done)
