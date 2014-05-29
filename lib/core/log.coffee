{inspect} = require 'util'
_ = require 'lodash'
bus = require '../bus'
logLevels = require './logLevels'

channel = 'axiom.log'

api = {channel, logLevels}

logLevels.forEach ({topic, color}, index) ->
  api[topic] = (data...) ->
    bus.publish {channel, topic, data}

api.coreEntry = (method, args) ->
  message = "Calling 'core.#{method}' with args:\n"
  api.debug message, args

module.exports = api
