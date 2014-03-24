bus = require '../bus'
_ = require 'lodash'

defaultConfig = ->
  return {
    blacklist: []
    timeout: 2000
    app: {}
  }

# internal state to keep track of the resources that have been loaded
module.exports = internal =

  # A place to record what responders we have attached
  responders: {}

  config: defaultConfig()

  retriever: undefined

  contexts: {}

  setDefaultContext: (ns) ->
    internal.contexts[ns] ?= {
      app: internal.config.app
      axiom: require '../core'
      util: _.merge {}, internal.retriever
      config: {}
    }
    return internal.contexts[ns]

  reset: ->
    internal.responders = {}
    internal.config = defaultConfig()
    internal.contexts = {}

    bus.reset()
