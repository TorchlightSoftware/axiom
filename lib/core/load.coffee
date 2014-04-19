_ = require 'lodash'
law = require 'law'

internal = require './internal'
request = require './request'
respond = require './respond'

module.exports = (moduleName, module={}) ->
  core = require '../core'
  core.log.coreEntry 'load', {moduleName}

  config = module.config or {}

  # Merge config overrides from '<projectRoot>/axiom/<moduleName>'
  try
    projectOverrides = internal.retriever.retrieve('axiom_configs', moduleName)

  if (typeof projectOverrides) is 'function'
    projectOverrides = projectOverrides(internal.config.general)

  _.merge config, projectOverrides

  # config is now immutable
  Object.freeze(config)

  # Initialize the services using a project-relative 'lib' resolver
  services = law.create {services: module.services}

  if module.protocol
    for namespace, processes of module.protocol
      for processName, settings of processes
        core.loadProcess(namespace, processName, settings)

  #for serviceName, options of config

    #do (serviceName, options) ->
      #serviceChannel = "#{moduleName}.#{serviceName}"

      #if options.base
        #baseChannel = "base.#{options.base}"
        #respond serviceChannel, (args, done) ->
          #request baseChannel, {
            #moduleName
            #serviceName
            #args
            #config: options
            #axiom: core
          #}, done

  for serviceName, serviceDef of services
    context = Object.freeze {
      moduleName
      serviceName
      general: internal.config.general
      config
      axiom: core
      util: internal.retriever
    }

    serviceDef = serviceDef.bind(context)

    # Respond at defined attachment points
    attachments = module.attachments?[serviceName]
    if attachments
      for attach in attachments
        respond "#{attach}", serviceDef

    # Attach a responder at the standard location
    respond "#{moduleName}.#{serviceName}", serviceDef
