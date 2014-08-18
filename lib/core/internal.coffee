bus = require '../bus'
_ = require 'lodash'
logger = require 'torch'

defaultConfig = ->
  return {

    # The protocol this system is running
    protocol: {}

    # Any extensions we will load
    extensions: {}

    # Routes that were passed to us, to be configured as links
    routes: {}

    timeout: 2000
    logDepth: 5
    general: {}
  }

defaultRetriever = require '../retriever'

# internal state to keep track of the resources that have been loaded
module.exports = internal =

  # A place to record what responders we have attached
  responders: {}

  # A place to record what channels are linked
  links: {}

  # get responders and linked responders for a channel
  getResponders: (channel) ->
    allResponders = _.keys @responders[channel]

    # add any responders on linked channels
    for l of @links
      if channel.substring(0, l.length) is l
        for ns in @links[l]
          target = channel.replace l, ns
          allResponders.push _.keys(@responders[target])...

    return allResponders

  config: defaultConfig()

  retriever: defaultRetriever

  reset: (done) ->
    done ?= ->
    core = require '../core'

    core.delegate "system.kill", {reason: 'core.reset'}, (err, args) ->
      internal.responders = {}
      internal.links = {}
      internal.config = defaultConfig()
      internal.retriever = defaultRetriever

      bus.reset()
      done(err, args)
