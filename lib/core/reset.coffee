internal = require './internal'

module.exports = (done) ->
  core = require '../core'
  core.log.coreEntry 'reset'

  internal.reset(done)
