bus = require '../bus'
_ = require 'lodash'
logger = require 'torch'

defaultConfig = ->
  return {
    blacklist: []
    timeout: 2000
    general: {}
  }

defaultRetriever = require '../retriever'

# internal state to keep track of the resources that have been loaded
module.exports = internal =

  # The protocol this system is running
  protocol: {}

  # Any extensions we will load
  extensions: {}

  # A place to record what responders we have attached
  responders: {}

  # A place to record what channels are linked
  links: {}

  # get responders and linked responders for a channel
  getResponders: (channel) ->
    allResponders = _.keys @responders[channel]

    # add any responders on linked channels
    if @links[channel]
      for l in @links[channel]
        allResponders.push _.keys(@responders[l])...

    return allResponders

  config: defaultConfig()

  retriever: defaultRetriever

  reset: (done) ->
    done ?= ->
    core = require '../core'
    core.delegate "system.kill", {reason: 'core.reset'}, (err, args) ->
      internal.protocol = {}
      internal.extensions = {}
      internal.responders = {}
      internal.links = {}
      internal.config = defaultConfig()
      internal.retriever = defaultRetriever

      bus.reset()
      done(err, args)
