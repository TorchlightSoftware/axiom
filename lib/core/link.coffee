_ = require 'lodash'
logger = require 'torch'

internal = require './internal'
ns_replace = require '../helpers/ns-replace'

bus = require '../bus'
{compare} = bus.configuration.resolver
compare = compare.bind(bus.configuration.resolver)

module.exports = (from, to) ->
  core = require '../core'
  core.log.coreEntry 'link', {from, to}

  internal.links[from] = _.union internal.links[from], [to]

  # link method supporting namespace forwarding
  bus.addWireTap (data, envelope) ->

    # use topic comparer on channel instead
    channelMatch = envelope.channel.substring(0, from.length) is from
    if channelMatch
      topicMatch = compare('request.#', envelope.topic)

      if topicMatch
        target = ns_replace(envelope.channel, from, to)
        newEnvelope = _.merge {}, envelope, {channel: target}
        bus.publish newEnvelope
