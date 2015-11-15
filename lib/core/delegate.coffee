timers = require 'timers'
_ = require 'lodash'

bus = require '../bus'
internal = require './internal'
send = require './send'
{DelegateTimeoutError, ErrorCollection} = require '../errorTypes'
logger = require 'torch'

module.exports = delegate = (channel, data, done) ->

  entryPoint = if delegate.caller.extensionName?
    delegate.caller
  else
    delegate

  core = require '../core'
  data ?= {}
  done ?= ->

  # Same as request, but for multiple recipients on one channel.
  # Wait until we receive a response from each recipient
  # Time out based on axiom config - report timeouts for each recipient

  # Get an array of responderId's of listeners from whom we expect
  # some kind of response on this channel.
  waitingOn = internal.getResponders(channel)

  core.log.coreEntry 'delegate', {channel, data, waitingOn}

  # return immediately if we have nothing to do
  if _.isEmpty waitingOn
    return done null, data

  # We will accumulate results in these objects, which map
  # responderId's to errors and results.
  errors = {}
  results = {}

  # Send the message
  replyTo = send channel, data

  # Define an 'onTimeout' callback for when we don't get a response
  # (either error or success) in the configured time.
  ms = internal.config.timeout
  onTimeout = ->
    waitingOn.map (responderId) ->
      err = new DelegateTimeoutError {channel, responderId, ms}, entryPoint

      bus.publish
        channel: replyTo.channel
        topic: replyTo.topic.err
        data: err
        responderId: responderId

  timeoutId = timers.setTimeout onTimeout, ms

  callback = (message, envelope) ->
    {responderId, extension} = envelope
    extension ?= responderId

    _.pull waitingOn, responderId

    [condition, middle..., topicId] = envelope.topic.split('.')

    switch condition

      when 'err'
        errors[extension] = message

      # merge the original input with the new message
      when 'success'
        if data?.__delegation_result
          base = data[extension] or data.__input
          results[extension] = _.merge {}, base, message
        else
          results[extension] = _.merge {}, data, message

    core.log.debug "Delegate received: #{channel}:#{envelope.topic}, remaining: #{waitingOn.length}"
    if waitingOn.length is 0
      errSub.unsubscribe()
      successSub.unsubscribe()
      timers.clearTimeout timeoutId

      unless _.isEmpty errors
        err = new ErrorCollection {channel, errors}, entryPoint

      results.__delegation_result = true
      results.__input = data.__input or data
      #core.log.debug "Delegate #{channel}.#{replyTo.topicId} calling done."
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
