logger = require 'torch'
applicationBus = require "./applicationBus"

module.exports =
  (module, done) ->
    {config, services} = module
    moduleName = module.name

    for serviceName, serviceDef of services
      # determine the topic to listen on
      serviceChannel = "#{moduleName}.#{serviceName}"
      #logger.white "attaching to:", serviceChannel

      # attach service to a 'completed' topic
      readyService = (args, env) ->
        serviceDef args, (err, result) ->
          if err?
            applicationBus.publish "error", err
            applicationBus.publish "#{serviceChannel}.error", err
          else
            applicationBus.publish "#{serviceChannel}.success", result

      # attach service to base topic
      applicationBus.subscribe serviceChannel, readyService

    done()
