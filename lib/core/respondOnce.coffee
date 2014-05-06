internal = require './internal'
_ = require 'lodash'

module.exports = (channel, service) ->
  core = require '../core'
  core.log.coreEntry 'respondOnce', {channel}

  sub = core.respond channel, (args, done) ->
    core.log.debug 'detaching responder from:', {channel}

    # remove this responder
    sub.unsubscribe()
    delete internal.responders[channel][sub.responderId]
    delete internal.responders[channel] if _.isEmpty internal.responders[channel]

    # pass through to the normal service
    service(args, done)
