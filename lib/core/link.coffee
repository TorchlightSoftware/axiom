_ = require 'lodash'
internal = require './internal'
logger = require 'torch'

bus = require '../bus'
{compare} = bus.configuration.resolver
compare = compare.bind(bus.configuration.resolver)

module.exports = (from, to) ->
  core = require '../core'
  core.log.coreEntry 'link', {from, to}

  internal.links[from] = _.union internal.links[from], [to]

  # NOTE: former, simpler link method
  #bus.linkChannels(
    #{channel: from, topic: 'request.#'}
    #{channel: to}
  #)

  # link method supporting namespace forwarding
  bus.addWireTap (data, envelope) ->

    # use topic comparer on channel instead
    channelMatch = envelope.channel.substring(0, from.length) is from
    if channelMatch
      topicMatch = compare('request.#', envelope.topic)
      if topicMatch

        target = envelope.channel.replace from, to
        bus.publish _.merge {}, envelope, {channel: target}
