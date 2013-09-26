logger = require 'torch'
bus = require './bus'

module.exports =
  (module, done) ->
    {config, services} = module
    moduleName = module.name

    for namespace, options of config
      logger.red 'NOT IMPLEMENTED'

    for serviceName, serviceDef of services
      serviceChannel = "#{moduleName}.#{serviceName}"
      core.respond serviceChannel, serviceDef

    done()
