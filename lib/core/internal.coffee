bus = require '../bus'

# internal state to keep track of the resources that have been loaded
module.exports = internal =

  # A place to record what responders we have attached
  responders: {}

  config:
    blacklist: []
    timeout: 2000

  retriever: undefined

  reset: ->
    internal.responders = {}
    internal.config =
      blacklist: []
      timeout: 2000

    bus.utils.reset()
