uuid = require 'uuid'

bus = require './bus'

getTopicId = (topic) -> topic.split('.').pop()
makeRequestTopic = (topic) ->
  topicId = getTopicId topic
  return "request.#{topicId}"

makeResponseTopic = (topic) ->
  topicId = getTopicId topic
  return "response.#{topicId}"


module.exports =
  init: ->
    # require each axiom module
    # pass to load

  request: (channel, data, done) ->
    # subscribe to a response address
    # publish a message, with a response address in the envelope
    # time out based on axiom config

    # default callback is of signature (message, envelope).
    # wrap so we can pass a conventional (err, result)-style callback.
    callback = (message, envelope) ->
      done null, message

    topicId = uuid.v1()

    replyTo =
      channel: channel
      topic: "response.#{topicId}"

    bus.subscribe {
      channel: replyTo.channel
      topic: replyTo.topic
      callback: callback
    }

    bus.publish {
      channel: channel
      topic: "request.#{topicId}"
      data: data
      replyTo: replyTo
    }

  delegate: (channel, data, done) ->
    # same as request, but for multiple recipients
    # ask each recipient to acknowledge receipt
    # wait until we receive a response from each recipient
    # time out based on axiom config - report timeouts for each recipient

  respond: (channel, handler) ->
    # can respond to request or delegate (or should we split this out?)
    # sends acknowledgement, error, completion to replyTo channels
    callback = (message, envelope) ->
      handler message, (err, result) ->
        if err?
          topic = envelope.replyTo.errTopic
          data = err
        else
          topic = envelope.replyTo.successTopic
          data = result

        bus.publish {
          channel: envelope.replyTo.channel
          topic: topic
          data: data
        }

    bus.subscribe {
      channel: channel
      topic: 'request.#'
      callback: callback
    }

  send: (channel, data) ->
    # just send the message

  listen: (channel, handler) ->
    # just listen

  signal: (channel, data) ->
    # for sending interrupts
