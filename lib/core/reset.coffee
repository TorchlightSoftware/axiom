internal = require './internal'

module.exports = ->
  core = require '../core'
  core.log.coreEntry 'reset'

  internal.reset()
