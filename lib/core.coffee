uuid = require 'uuid'

bus = require './bus'
postal = bus

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
      {topic} = envelope
      [condition, _..., topicId] = topic.split('.')
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

    # subscribe to the 'err' response for topicId
    errSub = new bus.SubscriptionDefinition(
      replyTo.channel,
      replyTo.topic.err,
    )
    errSub.subscribe callback

    # subscribe to the 'success' response for topicId
    successSub = new bus.SubscriptionDefinition(
      replyTo.channel,
      replyTo.topic.success
    )
    successSub.subscribe (message, envelope) ->
      errSub.unsubscribe()
      callback message, envelope
    successSub.once()

    bus.publish
      channel: channel
      topic: "request.#{topicId}"
      data: data
      replyTo: replyTo

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
