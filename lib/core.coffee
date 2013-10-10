path = require 'path'

timers = require 'timers'
logger = require 'torch'

law = require 'law'
uuid = require 'uuid'
async = require 'async'
_ = require 'lodash'

bus = require './bus'


getAxiomModules = (config) ->
  config or= {}
  {blacklist} = config

  # Grab 'package.json' as an object
  packageJson = require path.join(__dirname, '..', 'package.json')

  # Extract the NPM module names of the 'dependencies'
  dependencies = Object.keys packageJson.dependencies

  # Filter out non-axiom NPM modules
  axiomNpmModules = dependencies.filter (dep) -> /^axiom-\S\S*/.test dep

  # Remove the 'axiom-' prefix
  axiomModules = axiomNpmModules.map (m) -> m.slice('axiom-'.length)

  # We only want the axiom modules not blacklisted, so take the
  # set difference of 'axiomModules' \ 'blacklist'.
  axiomModules = _.difference axiomModules, blacklist

  return axiomModules


core =
  modules: getAxiomModules()

  config:
    blacklist: []
    timeout: 2000

  # a place to record what responders we have attached
  responders: {}

  init: (config, modules) ->
    core.reset()
    modules or= []
    _.merge core.config, config
    core.modules = _.union core.modules, modules

    # Require and load axiom-base
    base = require 'axiom-base'
    core.load 'base', base

    # Require each axiom module.
    # Pass to load.
    for moduleName in core.modules
      # In case we have passed in a blacklisted module
      continue if moduleName in core.config.blacklist

      module = require "axiom-#{moduleName}"
      core.load moduleName, module

  reset: ->
    core.responders = {}
    core.modules = getAxiomModules()
    bus.utils.reset()

  load: (moduleName, module) ->
    {config} = module
    config or= []
    services = law.create module

    for serviceName, options of config
      do (serviceName, options) ->
        serviceChannel = "#{moduleName}.#{serviceName}"

        if options.base
          baseChannel = "base.#{options.base}"
          core.respond serviceChannel, (args, done) ->
            core.request baseChannel, {
              moduleName
              serviceName
              args
              config: options
              axiom: core
            }, done

    for serviceName, serviceDef of services
      # attach a responder for each service definition
      core.respond "#{moduleName}.#{serviceName}", serviceDef

      # check the root namespace for this service, and see if we have an alias for it
      [namespace] = serviceName.split '/'
      alias = config?[namespace]?.extends
      if alias

        # attach an aliased responder
        core.respond "#{alias}.#{serviceName}", serviceDef


  # Subscribe to a response address.
  # Publish a message, with a response address in the envelope.
  # Time out based on axiom config.
  request: (channel, data, done) ->

    # Send the message
    replyTo = core.send channel, data


    # Define an 'onTimeout' callback for when we don't get a response
    # (either error or success) in the configured time.
    onTimeout = ->
      err = new Error "Request timed out on channel '#{channel}'"

      bus.publish
        channel: replyTo.channel
        topic: replyTo.topic.err
        data: err

    timeoutId = timers.setTimeout onTimeout, core.config.timeout

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


  delegate: (channel, data, done) ->
    # Same as request, but for multiple recipients on one channel.
    # Wait until we receive a response from each recipient
    # Time out based on axiom config - report timeouts for each recipient

    # Get an array of responderId's of listeners from whom we expect
    # some kind of response on this channel.
    responders = core.responders[channel] or {}
    waitingOn = _.keys responders

    # return immediately if we have nothing to do
    if _.isEmpty waitingOn
      return done()

    # We will accumulate results in these objects, which map
    # responderId's to errors and results.
    errors = {}
    results = {}

    # Send the message
    replyTo = core.send channel, data

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

  # sends acknowledgement, error, completion to replyTo channels
  respond: (channel, service) ->
    responderId = uuid.v1()

    callback = (message, envelope) ->
      service message, (err, result) ->
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
    core.responders[channel][responderId] =
      callback: callback

    # Actually subscribe as a responder
    bus.subscribe
      channel: channel
      topic: 'request.#'
      callback: callback

  # just send the message
  send: (channel, data) ->
    topicId = uuid.v1()
    replyTo =
      channel: channel
      topicId: topicId
      topic:
        err: "err.#{topicId}"
        info: "info.#{topicId}"
        success: "success.#{topicId}"

    timers.setImmediate ->
      topic = "request.#{topicId}"
      bus.publish
        channel: channel
        topic: topic
        data: data
        replyTo: replyTo

    return replyTo

  # just listen
  listen: (channel, topic, callback) ->
    sub = bus.subscribe
      channel: channel
      topic: topic
      callback: (data, envelope) ->
        err = null
        callback err, envelope

  # for sending interrupts
  signal: (channel, data) ->


module.exports = core