timers = require 'timers'

uuid = require 'uuid'
async = require 'async'
_ = require 'lodash'

bus = require './bus'


getTopicId = (topic) -> topic.split('.').pop()

defaultConfig =
  timeout: 2000

module.exports = core =
  init: (config) ->
    # Require each axiom module.
    # Pass to load.
    core.config = _.merge {}, defaultConfig
    core.config = _.merge core.config, config

  request: (channel, data, done) ->
    # Subscribe to a response address.p
    # Publish a message, with a response address in the envelope.
    # Time out based on axiom config.

    # Define an 'onTimeout' callback for when we don't get a response
    # (either error or success) in the configured time.
    timeout = core.config.timeout
    onTimeout = ->
      msg = "Request timed out on channel '#{channel}'"
      err = new Error msg
      done err
    timeoutId = timers.setTimeout onTimeout, timeout

    # Default callback is of signature (message, envelope).
    # Wrap so we can pass a conventional (err, result)-style callback.
    callback = (message, envelope) ->
      # Either an error or a success response has been
      # received, so cancel our timeout callback.
      timers.clearTimeout timeoutId

      {topic} = envelope
      [condition, middle..., topicId] = topic.split('.')
      switch condition
        when 'err'
          err = message
          done err
        when 'success'
          done null, message
        else
          # This should never be reached, as this callback should only
          # be invoked by a subscription to a topic of the form
          # 'err.<uuid>' or 'success.<uuid>'.
          err = new Error "Invalid condition '#{condition}'for response with topicId '#{topicId}'"
          done err

    topicId = uuid.v1()

    replyTo =
      channel: channel
      topic:
        err: "err.#{topicId}"
        info: "info.#{topicId}"
        success: "success.#{topicId}"

    # Subscribe to the 'err' response for topicId
    # We don't pass a callback immediately so that we can
    # refer to the subscription itself in the callback.
    errSub = bus.subscribe {
      channel: replyTo.channel,
      topic: replyTo.topic.err,
    }
    errSub.subscribe callback

    # Subscribe to the 'success' response for topicId
    # As above, we don't pass a callback immediately so that
    # we can refer to the subscription itself in the callback.
    successSub = bus.subscribe {
      channel: replyTo.channel
      topic: replyTo.topic.success
    }
    successSub.subscribe (message, envelope) ->
      # Stop listening for errors by detaching the error callback
      errSub.unsubscribe()

      # Actually call the callback
      callback message, envelope

    # The success callback should only fire once, if at all
    successSub.once()

    bus.publish
      channel: channel
      topic: "request.#{topicId}"
      data: data
      replyTo: replyTo



  delegate: (channels, data, done) ->
    # Same as request, but for multiple recipients
    # ask each recipient to acknowledge receipt
    # wait until we receive a response from each recipient
    # time out based on axiom config - report timeouts for each recipient

    # Wrap 'core.request' in a signature compatible with 'async.map'
    request = (ch, next) ->
      core.request ch, data, (err, result) ->
        next err, result
    # Make 'core.request's on each channel, in parallel
    async.map channels, request, done

  respond: (channel, handler) ->
    # can respond to request or delegate (or should we split this out?)
    # sends acknowledgement, error, completion to replyTo channels
    callback = (message, envelope) ->
      handler message, (err, result) ->
        if err?
          topic = envelope.replyTo.topic.err
          data = err
        else
          topic = envelope.replyTo.topic.success
          data = result

        bus.publish
          channel: envelope.replyTo.channel
          topic: topic
          data: data

    bus.subscribe
      channel: channel
      topic: 'request.#'
      callback: callback

  send: (channel, data) ->
    # just send the message

  listen: (channel, handler) ->
    # just listen

  signal: (channel, data) ->
    # for sending interrupts
