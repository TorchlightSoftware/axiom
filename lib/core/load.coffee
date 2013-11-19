_ = require 'lodash'
law = require 'law'

internal = require './internal'
request = require './request'
respond = require './respond'
log = require './log'

module.exports = (moduleName, module) ->
  log.info "Calling 'core.load'"

  # lazy load this to avoid circular dependency
  core = require '../core'

  config = _.merge {}, (module.config or {})

  # Merge config overrides from '<projectRoot>/axiom/<moduleName>'
  try
    _.merge config, internal.retriever.retrieve('axiom', moduleName)

  # Initialize the services using a project-relative 'lib' resolver
  services = law.create {services: module.services}

  contexts = {}

  # Give each service a binding context containing the config.
  # The context is shared between all services in a namespace.
  for name, def of services
    [namespace] = name.split '/'
    unless contexts[namespace]
      contexts[namespace] = {
        config: config[namespace]
        axiom: core
        util: _.merge {}, internal.retriever
      }

    services[name] = def.bind contexts[namespace]

  for serviceName, options of config
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
    # Attach a responder for each service definition
    respond "#{moduleName}.#{serviceName}", serviceDef

    # Check the root namespace for this service, and see if we have an alias for it
    [namespace] = serviceName.split '/'
    alias = config?[namespace]?.extends
    if alias

      # attach an aliased responder
      respond "#{alias}.#{serviceName}", serviceDef