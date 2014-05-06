_ = require 'lodash'
law = require 'law'

internal = require './internal'
request = require './request'
respond = require './respond'
getSafeCore = require '../getSafeCore'
getSafeRetriever = require '../getSafeRetriever'

module.exports = (extensionName, extension) ->
  core = require '../core'
  core.log.coreEntry 'load', {extensionName}

  unless extension?
    core.log.warning "Loading #{extensionName} with no corresponding definition."
    extension = {}

  config = extension.config or {}

  # Merge config overrides from '<projectRoot>/axiom/<extensionName>'
  try
    projectOverrides = internal.retriever.retrieve('axiom_configs', extensionName)

  if (typeof projectOverrides) is 'function'
    projectOverrides = projectOverrides(internal.config.general)

  _.merge config, projectOverrides

  # config is now immutable
  Object.freeze(config)

  # Initialize the services using a project-relative 'lib' resolver
  services = law.create {services: extension.services}

  # load protocol/processes if present
  if extension.protocol
    for namespace, processes of extension.protocol
      for processName, settings of processes
        core.loadProcess(namespace, processName, settings)

  safeCore = getSafeCore(extensionName, core, extension.protocol?)
  safeRetriever = getSafeRetriever(extensionName, internal.retriever)

  for serviceName, serviceDef of services
    context = Object.freeze {
      extensionName
      serviceName
      config
      general: internal.config.general
      axiom: safeCore
      retriever: safeRetriever
    }

    serviceDef = serviceDef.bind(context)
    serviceDef.extension = extensionName

    # Respond at defined attachment points
    attachments = extension.attachments?[serviceName]
    if attachments
      for attach in attachments
        respond "#{attach}", serviceDef

    # Attach a responder at the standard location
    respond "#{extensionName}.#{serviceName}", serviceDef
