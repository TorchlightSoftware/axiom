timers = require 'timers'
_ = require 'lodash'

bus = require '../bus'
{ NoRespondersError
  AmbiguousRespondersError
  RequestTimeoutError} = require '../errorTypes'

internal = require './internal'
send = require './send'
ns_replace = require '../helpers/ns-replace'

request = (channel, data, done) ->
  core = require '../core'
  core.log.coreEntry 'request', {channel, data}

  entryPoint = if request.caller.extensionName?
    request.caller
  else
    request

  # How many responders do we have
  responders = internal.getResponders(channel)

  switch responders.length
    when 0
      err = new NoRespondersError {channel}, entryPoint
      return done err, {}

    when 1
      # Send the message
      replyTo = send channel, data

    else
      err = new AmbiguousRespondersError {responders, channel}, entryPoint
      return done err, {}

  # Define an 'onTimeout' callback for when we don't get a response
  # (either error or success) in the configured time.
  ms = internal.config.timeout
  onTimeout = ->
    err = new RequestTimeoutError {channel, ms}, entryPoint

    bus.publish
      channel: replyTo.channel
      topic: replyTo.topic.err
      data: err

  timeoutId = timers.setTimeout onTimeout, ms

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
        done message, {}
      when 'success'
        done null, message

      else
        # This should never be reached, as this callback should only
        # be invoked by a subscription to a topic of the form
        # 'err.<uuid>' or 'success.<uuid>'.
        err = new Error "Invalid condition '#{condition}' for response with topicId '#{topicId}'"
        done err, {}

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

# 'mongoose.resources'
# 'carts/show'
# => 'mongoose.resources/carts/show'
request.ns = (path) ->
  unless /\/$/.test path
    path = path + '/'

  (channel, data, done) ->
    target = ns_replace channel, '', path
    request(target, data, done)

module.exports = request
