_ = require 'lodash'
async = require 'async'
logger = require 'torch'

module.exports = (namespace, processName, settings) ->
  core = require '../core'
  core.log.coreEntry 'loadProcess', {namespace, processName, settings}

  {type, signals} = settings

  if type in ['agent', 'task']
    process = (args, finished) ->

      processState =
        __delegation_result: true
        __input: args

      # a helper to run the pipeline in series
      runPipeline = (signal, args, done) ->
        stageNames = signals[signal]
        return done() unless stageNames

        core.log.debug 'running pipeline:', {signal, stageNames}

        runStage = (stageName) ->
          (args, next) ->
            service = "#{namespace}.#{processName}/#{stageName}"
            core.delegate service, args, (err, result) ->
              _.merge processState, result unless err?
              next err, processState

        stages = stageNames.map(runStage)
        stages[0] = stages[0].bind null, args

        async.waterfall stages, done

      # attach the signal to the pipeline
      attachSignal = (signal, once) ->
        attach = if once then core.respondOnce else core.respond
        attach "#{namespace}.#{processName}/#{signal}", (args, done) ->
          args = _.merge {}, processState, {__input: args}
          runPipeline signal, args, done

      # set up responders for each signal
      for signal of signals when signal not in ['start', 'stop']
        attachSignal signal

      # queue the start signal
      signalList = [
        runPipeline.bind(null, 'start', processState)
      ]

      # queue the stop signal
      if type is 'task' and signals.stop?
        signalList.push runPipeline.bind(null, 'stop')

      # or listen for the stop signal
      else
        attachSignal 'stop', true
        core.link 'system.kill', "#{namespace}.#{processName}/stop"

      async.waterfall signalList, finished

    core.respond "#{namespace}.#{processName}", process
