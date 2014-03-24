uuid = require 'uuid'
logger = require 'torch'

bus = require '../bus'
internal = require './internal'

module.exports = (channel, service) ->
  core = require '../core'
  core.log.coreEntry 'respond', {channel}

  # Give each service a binding context containing the config.
  # The context is shared between all services in a namespace.
  [namespace] = channel.split '/'
  service = service.bind(internal.setDefaultContext(namespace))

  #logger.magenta "binding '#{channel}' to namespace '#{namespace}':", internal.contexts[namespace]

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
  internal.responders[channel] or= {}
  internal.responders[channel][responderId] =
    callback: callback

  # Actually subscribe as a responder
  bus.subscribe
    channel: channel
    topic: 'request.#'
    callback: callback
