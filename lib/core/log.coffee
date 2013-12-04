{inspect} = require 'util'
_ = require 'lodash'
bus = require '../bus'
logLevels = require './logLevels'

channel = 'axiom.log'

api = {channel, logLevels}

logLevels.forEach ({topic, color}, index) ->
  api[topic] = (data) ->
    bus.publish {channel, topic, data}

api.coreEntry = (method, args) ->
  message = "Calling 'core.#{method}'"
  unless _.isEmpty args
    message += " with args: #{inspect(args, null, null)}"
  api.debug message

module.exports = api
