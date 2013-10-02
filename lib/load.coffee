logger = require 'torch'
_ = require 'lodash'
bus = require './bus'
core = require './core'


module.exports =
  (module, done) ->
    {config, services} = module
    moduleName = module.name

    for serviceName, options of config
      serviceChannel = "#{moduleName}.#{serviceName}"
      {base} = options
      rest = _.omit options, 'base'

      baseChannel = "base.#{serviceName}"
      core.respond serviceChannel, (args, done) ->
        core.request baseChannel, args, done

    for serviceName, serviceDef of services
      serviceChannel = "#{moduleName}.#{serviceName}"
      core.respond serviceChannel, serviceDef

    done()
