_ = require 'lodash'
async = require 'async'

module.exports = (namespace, processName, settings) ->
  core = require '../core'
  core.log.coreEntry 'loadProcess', {namespace, processName, settings}

  {type, signals} = settings

  if type in ['agent', 'task']
    process = (args, finished) ->

      # a helper to run the pipeline in series
      runPipeline = (args, stages, done) ->
        runStage = (stageName, next) ->
          core.log.debug 'delegating:', "#{namespace}.#{processName}/#{stageName}"
          core.delegate "#{namespace}.#{processName}/#{stageName}", args, next
        async.forEachSeries stages, runStage, done

      # set up responders for each signal
      for signal, pipeline of signals when signal isnt 'start'
        core.log.debug 'responding to signal:', "#{namespace}.#{processName}/#{signal}"
        core.respond "#{namespace}.#{processName}/#{signal}", (args, done) ->
          core.log.debug "running #{signal} pipeline:", pipeline
          runPipeline args, pipeline, done

      core.link 'system.kill', "#{namespace}.#{processName}/stop"

      # run the start signal
      core.log.debug 'running start signal:', signals.start

      signalList = [
        runPipeline.bind(runPipeline, args, signals.start)
      ]

      if type is 'task'
        core.log.debug 'running stop signal:', signals.stop
        signalList.push runPipeline.bind(runPipeline, args, signals.stop)

      async.series signalList, finished

    core.respond "#{namespace}.#{processName}", process
