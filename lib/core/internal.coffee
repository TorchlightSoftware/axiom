bus = require '../bus'

module.exports = internal =
  config: {}

  modules: []

  # A place to record what responders we have attached
  responders: {}

  retriever: undefined

  reset: ->
    internal.responders = {}
    internal.modules = []
    internal.config =
      blacklist: []
      timeout: 2000

    bus.utils.reset()