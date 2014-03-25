_ = require 'lodash'
bus = require '../bus'
internal = require './internal'

module.exports = (chanA, chanB) ->
  core = require '../core'
  core.log.coreEntry 'link', {chanA, chanB}

  internal.links[chanA] = _.union internal.links[chanA], [chanB]

  bus.linkChannels(
    {channel: chanA, topic: 'request.#'}
    {channel: chanB}
  )
