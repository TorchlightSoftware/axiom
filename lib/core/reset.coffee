internal = require './internal'
log = require './log'

module.exports = ->
  log.info "Calling 'core.reset'"
  internal.reset()