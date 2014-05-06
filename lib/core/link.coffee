_ = require 'lodash'
bus = require '../bus'
internal = require './internal'

module.exports = (from, to) ->
  core = require '../core'
  core.log.coreEntry 'link', {from, to}

  internal.links[from] = _.union internal.links[from], [to]

  bus.linkChannels(
    {channel: from, topic: 'request.#'}
    {channel: to}
  )
