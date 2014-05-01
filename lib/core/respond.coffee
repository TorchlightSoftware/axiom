uuid = require 'uuid'
{inspect} = require 'util'
_ = require 'lodash'

bus = require '../bus'
internal = require './internal'

module.exports = (channel, service) ->
  return unless (typeof service) is 'function'

  core = require '../core'
  core.log.coreEntry 'respond', {channel}

  responderId = uuid.v1()

  callback = (message, envelope) ->
    if message?.__delegation_result
      message = _.merge {}, message.__input, message[service.extension]

    service message, (err, result) ->
      core.log.debug "#{channel}:#{envelope.topic} responding: #{inspect {err, result}}"
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
        extension: service.extension

  # Create a unique identifier for this responder
  callback.responderId = responderId

  # Map this 'responderId' to the responder and its metadata
  internal.responders[channel] or= {}
  internal.responders[channel][responderId] =
    callback: callback

  # Actually subscribe as a responder
  subscription = bus.subscribe
    channel: channel
    topic: 'request.#'
    callback: callback

  subscription.responderId = responderId

  # return subscription so it can be cancelled
  # and the responderId can be compared
  return subscription
