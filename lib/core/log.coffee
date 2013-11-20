bus = require '../bus'
logLevels = require './logLevels'

channel = 'axiom.log'

api = {channel, logLevels}

logLevels.forEach ({topic, color}, index) ->
  api[topic] = (data) ->
    bus.publish {channel, topic, data}

module.exports = api
