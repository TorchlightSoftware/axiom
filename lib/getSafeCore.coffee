_ = require 'lodash'

module.exports = (extensionName, core) ->

  # prefix the channel with the extensionName
  limit = (fn) ->
    safe = (channel, args...) ->
      fn "#{extensionName}.#{channel}", args...
    safe.extensionName = extensionName
    return safe

  api = {
    # TODO: limit to extension and create default routing
    log: _.omit core.log, 'coreEntry'
  }

  # all these functions take 'channel' as their first arg,
  # so apply 'limit' to them to limit the namespace
  for fn in ['request', 'delegate', 'respond', 'respondOnce', 'send', 'listen']
    api[fn] = limit core[fn]

  return Object.freeze api
