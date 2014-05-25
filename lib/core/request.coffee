timers = require 'timers'
_ = require 'lodash'

bus = require '../bus'
{ NoRespondersError
  AmbiguousRespondersError
  TimeoutError} = require '../errors'

internal = require './internal'
send = require './send'

module.exports = (channel, data, done) ->
  core = require '../core'
  core.log.coreEntry 'request', {channel, data}

  # How many responders do we have
  responders = internal.getResponders(channel)

  switch responders.length
    when 0
      return done new NoRespondersError {channel}

    when 1
      # Send the message
      replyTo = send channel, data

    else
      return done new AmbiguousRespondersError {responders, channel}

  # Define an 'onTimeout' callback for when we don't get a response
  # (either error or success) in the configured time.
  onTimeout = ->
    err = new TimeoutError {channel}

    bus.publish
      channel: replyTo.channel
      topic: replyTo.topic.err
      data: err

  timeoutId = timers.setTimeout onTimeout, internal.config.timeout

  # Default callback is of signature (message, envelope).
  # Wrap so we can pass a conventional (err, result)-style callback.
  callback = (message, envelope) ->

    # We're done, so cancel timeouts and subscriptions.
    timers.clearTimeout timeoutId
    errSub.unsubscribe()
    successSub.unsubscribe()

    [condition, middle..., topicId] = envelope.topic.split('.')

    switch condition
      when 'err'
        done message
      when 'success'
        done null, message

      else
        # This should never be reached, as this callback should only
        # be invoked by a subscription to a topic of the form
        # 'err.<uuid>' or 'success.<uuid>'.
        err = new Error "Invalid condition '#{condition}' for response with topicId '#{topicId}'"
        done err

  # Subscribe to the 'err' response for topicId
  # We don't pass a callback immediately so that we can
  # refer to the subscription itself in the callback.
  errSub = bus.subscribe {
    channel: channel
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

  return replyTo
