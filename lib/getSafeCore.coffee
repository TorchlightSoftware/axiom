_ = require 'lodash'

module.exports = (extensionName, core, isProtocol) ->

  # prefix the channel with the extensionName
  limit = (fn) ->
    (channel, args...) ->
      fn "#{extensionName}.#{channel}", args...

  api = {
    # TODO: limit to extension and create default routing
    log: _(core.log).without 'coreEntry'
  }

  # all these functions take 'channel' as their first arg,
  # so apply 'limit' to them to limit the namespace
  for fn in ['request', 'delegate', 'respond', 'respondOnce', 'send', 'listen']
    api[fn] = limit core[fn]

  if isProtocol
    api.link = core.link

  return Object.freeze api
