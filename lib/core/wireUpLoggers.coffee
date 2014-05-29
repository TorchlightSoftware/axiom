_ = require 'lodash'
moment = require 'moment'

internal = require './internal'

module.exports = (loggers=[]) ->
  core = require '../core'
  {channel, logLevels} = core.log
  getIndex = (name) -> _.findIndex logLevels, ({topic}) -> topic is name

  loggers.forEach ({writer, level}) ->
    return unless writer?
    level or= 'info'
    targetIndex = getIndex(level)

    if writer is 'console'
      logger = require 'torch'
      logger.setDepth internal.config.logDepth

      writer = (err, envelope) ->
        {timeStamp, data, topic} = envelope
        time = moment(timeStamp).format('YYYY/MM/DD HH:mm:ss Z')
        {color} = _.find logLevels, (l) -> topic is l.topic

        logger[color] "[#{time} #{topic.toUpperCase()}]", data...

    logLevels.forEach ({topic, color}, index) ->
      if index <= targetIndex
        core.listen channel, topic, writer
