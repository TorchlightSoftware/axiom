timers = require 'timers'
uuid = require 'uuid'

bus = require '../bus'

module.exports = (channel, data) ->
  core = require '../core'
  core.log.coreEntry 'send', {channel, data}

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
