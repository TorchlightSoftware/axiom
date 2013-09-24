logger = require 'torch'
bus = require './bus'

module.exports =
  (module, done) ->
    {config, services} = module
    moduleName = module.name

    for namespace, options of config
      logger.red 'NOT IMPLEMENTED'

    for serviceName, serviceDef of services
      # determine the topic to listen on
      serviceChannel = "#{moduleName}.#{serviceName}"
      #logger.white "attaching to:", serviceChannel

      # attach service to a 'completed' topic
      readyService = (args, env) ->
        serviceDef args, (err, result) ->
          if err?
            bus.publish "error", err
            bus.publish "#{serviceChannel}.error", err
          else
            bus.publish "#{serviceChannel}.success", result

      # attach service to base topic
      bus.subscribe serviceChannel, readyService

    done()
