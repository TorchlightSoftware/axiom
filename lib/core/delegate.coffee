timers = require 'timers'
_ = require 'lodash'

bus = require '../bus'
internal = require './internal'
send = require './send'
log = require './log'

module.exports = (channel, data, done) ->
  log.info "Calling 'core.delegate'"

  # Same as request, but for multiple recipients on one channel.
  # Wait until we receive a response from each recipient
  # Time out based on axiom config - report timeouts for each recipient

  # Get an array of responderId's of listeners from whom we expect
  # some kind of response on this channel.
  responders = internal.responders[channel] or {}
  waitingOn = _.keys responders

  # return immediately if we have nothing to do
  if _.isEmpty waitingOn
    return done()

  # We will accumulate results in these objects, which map
  # responderId's to errors and results.
  errors = {}
  results = {}

  # Send the message
  replyTo = send channel, data

  # Define an 'onTimeout' callback for when we don't get a response
  # (either error or success) in the configured time.
  timeout = internal.config.timeout
  onTimeout = ->
    waitingOn.map (responderId) ->
      msg = "Responder with id #{responderId} timed out on channel '#{channel}'"
      err = new Error msg

      bus.publish
        channel: replyTo.channel
        topic: replyTo.topic.err
        data: err
        responderId: responderId

  timeoutId = timers.setTimeout onTimeout, timeout

  callback = (message, envelope) ->
    {responderId} = envelope
    _.pull waitingOn, responderId

    [condition, middle..., topicId] = envelope.topic.split('.')

    switch condition
      when 'err'
        errors[responderId] =
          err: message
          envelope: envelope
      when 'success'
        results[responderId] =
          data: message
          envelope: envelope

    if waitingOn.length is 0
      errSub.unsubscribe()
      successSub.unsubscribe()
      timers.clearTimeout timeoutId

      unless _.isEmpty errors
        err = new Error "Errors returned by responders on channel '#{channel}'"
        err.errors = errors

      done err, results

  # Subscribe to the 'err' response for topicId
  # We don't pass a callback immediately so that we can
  # refer to the subscription itself in the callback.
  errSub = bus.subscribe {
    channel: replyTo.channel
    topic: replyTo.topic.err
    callback: callback
  }

  # Subscribe to the 'success' response for topicId
  # As above, we don't pass a callback immediately so that
  # we can refer to the subscription itself in the callback.
  successSub = bus.subscribe {
    channel: replyTo.channel
    topic: replyTo.topic.success
    callback: callback
  }
