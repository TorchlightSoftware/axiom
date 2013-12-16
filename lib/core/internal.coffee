bus = require '../bus'

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

  reset: ->
    internal.responders = {}
    internal.config = defaultConfig()

    bus.utils.reset()
