timers = require 'timers'
logger = require 'torch'

law = require 'law'
uuid = require 'uuid'
async = require 'async'
_ = require 'lodash'

bus = require './bus'

getTopicId = (topic) -> topic.split('.').pop()

defaultConfig =

module.exports = core =

  # for troubleshooting/wiretapping
  bus: bus

  config:
    timeout: 2000

  # a place to record what responders we have attached
  responders: {}

  init: (config) ->
    _.merge core.config, config
    core.reset()

    # Require each axiom module.
    # Pass to load.

  reset: ->
    core.responders = {}
    bus.utils.reset()

  load: (moduleName, module) ->
    {config} = module
    services = law.create module

    for serviceName, options of config
      do (serviceName, options) ->
        serviceChannel = "#{moduleName}.#{serviceName}"

        if options.base
          baseChannel = "base.#{options.base}"
          core.respond serviceChannel, (args, done) ->
            core.request baseChannel, {moduleName, serviceName, args, config: options, axiom: core}, done

    for serviceName, serviceDef of services

      # attach a responder for each service definition
      core.respond "#{moduleName}.#{serviceName}", serviceDef

      # check the root namespace for this service, and see if we have an alias for it
      [namespace] = serviceName.split '/'
      alias = config?[namespace]?.extends
      if alias

        # attach an aliased responder
        core.respond "#{alias}.#{serviceName}", serviceDef


  request: (channel, data, done) ->
    # Subscribe to a response address.
    # Publish a message, with a response address in the envelope.
    # Time out based on axiom config.

    # Define a unique identifier for the message cycle
    topicId = uuid.v1()

    # Define metadata to put inside the envelope
    replyTo =
      channel: channel
      topic:
        err: "err.#{topicId}"
        info: "info.#{topicId}"
        success: "success.#{topicId}"

    # Define an 'onTimeout' callback for when we don't get a response
    # (either error or success) in the configured time.
    timeout = core.config.timeout
    onTimeout = ->
      err = new Error "Request timed out on channel '#{channel}'"

      bus.publish
        channel: replyTo.channel
        topic: replyTo.topic.err
        data: err

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


  delegate: (channel, data, done) ->
    # Same as request, but for multiple recipients on one channel.
    # Wait until we receive a response from each recipient
    # Time out based on axiom config - report timeouts for each recipient

    # Get an array of responderId's of listeners from whom we expect
    # some kind of response on this channel.
    responders = core.responders[channel] or {}
    waitingOn = _.keys responders

    # We will accumulate results in these objects, which map
    # responderId's to errors and results.
    errors = {}
    results = {}

    # Define a unique identifier for the message cycle
    topicId = uuid.v1()

    # Define metadata to put inside the envelope
    replyTo =
      channel: channel
      topic:
        err: "err.#{topicId}"
        info: "info.#{topicId}"
        success: "success.#{topicId}"

    # Define an 'onTimeout' callback for when we don't get a response
    # (either error or success) in the configured time.
    timeout = core.config.timeout
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

    # Helper to pop a specific 'responderId' from the waitingOn array
    stopWaitingOn = (responderId) ->
      _.remove waitingOn, (el) -> el is responderId

    # Subscribe to the 'err' response for topicId
    # We don't pass a callback immediately so that we can
    # refer to the subscription itself in the callback.
    errSub = bus.subscribe {
      channel: replyTo.channel
      topic: replyTo.topic.err
    }
    errSub.subscribe (err, envelope) ->
      {responderId} = envelope
      stopWaitingOn responderId

      errors[responderId] =
        err: err
        envelope: envelope

    # Subscribe to the 'success' response for topicId
    # As above, we don't pass a callback immediately so that
    # we can refer to the subscription itself in the callback.
    successSub = bus.subscribe {
      channel: replyTo.channel
      topic: replyTo.topic.success
    }
    successSub.subscribe (data, envelope) ->
      {responderId} = envelope
      stopWaitingOn responderId

      results[responderId] =
        data: data
        envelope: envelope

    bus.publish
      channel: channel
      topic: "request.#{topicId}"
      data: data
      replyTo: replyTo

    finish = ->
      return timers.setImmediate finish if waitingOn.length > 0

      err = null
      unless _.isEmpty errors
        msg = "Errors returned by responders on channel '#{channel}'"
        err = new Error msg
        err.errors = errors

      errSub.unsubscribe()
      successSub.unsubscribe()

      done err, results

    timers.setImmediate finish

  # sends acknowledgement, error, completion to replyTo channels
  respond: (channel, handler) ->
    responderId = uuid.v1()

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
          responderId: responderId

    # Create a unique identifier for this responder
    callback.responderId = responderId

    # Map this 'responderId' to the responder and its metadata
    core.responders[channel] or= {}
    core.responders[channel][callback.responderId] =
      callback: callback

    # Actually subscribe as a responder
    bus.subscribe
      channel: channel
      topic: 'request.#'
      callback: callback

  # just send the message
  send: (channel, data) ->
    topicId = uuid.v1()
    topic = topicId
    pub = bus.publish
      channel: channel
      data: data
      topic: topic

  # just listen
  listen: (channel, handler) ->
    sub = bus.subscribe
      channel: channel
      topic: '#'
      callback: handler

  # for sending interrupts
  signal: (channel, data) ->
