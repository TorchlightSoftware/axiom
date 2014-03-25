_ = require 'lodash'
law = require 'law'
logger = require 'torch'

internal = require './internal'
request = require './request'
respond = require './respond'

module.exports = (moduleName, module={}) ->
  core = require '../core'
  core.log.coreEntry 'load', {moduleName}

  config = _.merge {}, module.config

  # Merge config overrides from '<projectRoot>/axiom/<moduleName>'
  try
    projectOverrides = internal.retriever.retrieve('axiom_configs', moduleName)

  if (typeof projectOverrides) is 'function'
    projectOverrides = projectOverrides(internal.config.app)

  _.merge config, projectOverrides

  # Initialize the services using a project-relative 'lib' resolver
  services = law.create {services: module.services}

  for serviceName, options of config

    # assign config values into the appropriate context
    if options.extends
      fullNS = "#{options.extends}.#{serviceName}"
    else
      fullNS = "#{moduleName}.#{serviceName}"
    internal.setDefaultContext(fullNS)
    _.merge internal.contexts[fullNS], {config: options}

    do (serviceName, options) ->
      serviceChannel = "#{moduleName}.#{serviceName}"

      if options.base
        baseChannel = "base.#{options.base}"
        respond serviceChannel, (args, done) ->
          request baseChannel, {
            moduleName
            serviceName
            args
            config: options
            axiom: core
          }, done

  for serviceName, serviceDef of services

    # Check the config for an 'extends'
    [namespace] = serviceName.split '/'
    alias = config?[namespace]?.extends
    if alias

      # Attach an aliased responder
      respond "#{alias}.#{serviceName}", serviceDef

    else

      # Attach a responder at the standard location
      respond "#{moduleName}.#{serviceName}", serviceDef
