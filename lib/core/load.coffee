_ = require 'lodash'
law = require 'law'

internal = require './internal'
respond = require './respond'
getSafeCore = require '../getSafeCore'
getSafeRetriever = require '../getSafeRetriever'
errorTypes = require '../errorTypes'

module.exports = (extensionName, extensionLocation) ->

  core = require '../core'
  core.log.coreEntry 'load', {extensionName}

  if extensionLocation is '*'
    extension = internal.retriever.retrieveExtension(extensionName)
  else if _.isString extensionLocation
    extension = internal.retriever.retrieve(extensionLocation)
  else if _.isObject extensionLocation
    extension = extensionLocation

  unless extension?
    return core.log.warning "Could not load extension '#{extensionName}'.  Unrecognized contents:", extensionLocation

  config = extension.config or {}

  # Merge config overrides from '<projectRoot>/axiom/<extensionName>'
  try
    projectOverrides = internal.retriever.retrieve('config', extensionName)

  if (typeof projectOverrides) is 'function'
    projectOverrides = projectOverrides.call(
      internal.retriever, internal.config.config
    )

  _.merge config, projectOverrides, internal.args?[extensionName]

  # config is now immutable
  Object.freeze(config)

  # Initialize the services using a project-relative 'lib' resolver
  services = law.create {services: extension.services}

  # load protocol/processes if present
  if extension.protocol
    for namespace, processes of extension.protocol
      for processName, settings of processes
        core.loadProcess(namespace, processName, settings)

  # Link to defined control points
  if extension.controls?
    for point, target of extension.controls
      core.link "#{extensionName}.#{point}", target

  appUtils = _.merge {}, core, {config: internal.config.config}
  for serviceName, serviceDef of services
    context = {
      extensionName
      serviceName
      config
      errorTypes
      systemConfig: internal.config.config
      appUtils: appUtils
      appRetriever: internal.retriever
    }
    _.merge context, getSafeCore(extensionName, core, extension.protocol?)
    _.merge context, getSafeRetriever(extensionName, internal.retriever)

    Object.freeze context

    serviceDef = serviceDef.bind(context)
    serviceDef.extension = extensionName

    # Respond at defined attachment points
    extensionPoints = extension.extends?[serviceName]
    if extensionPoints
      for attach in extensionPoints
        respond "#{attach}", serviceDef

    # Attach a responder at the standard location
    respond "#{extensionName}.#{serviceName}", serviceDef
