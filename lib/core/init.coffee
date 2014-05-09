_ = require 'lodash'

getAxiomModules = require '../getAxiomModules'
internal = require './internal'
load = require './load'

module.exports = (config, retriever) ->

  # override base retriever properties with provided retriever
  internal.retriever = _.merge {}, internal.retriever, retriever
  Object.freeze internal.retriever

  # Attempt to load a global 'axiom.*' file from the project root
  try
    projectConfig = internal.retriever.retrieve('config/axiom')
    _.merge internal.config, projectConfig

  # Merge in any programatically-passed config options
  _.merge internal.config, config
  Object.freeze internal.config

  # yay, logging
  core = require '../core'
  core.wireUpLoggers(internal.config.loggers)
  core.log.coreEntry 'init',
    config: internal.config
    retriever: internal.retriever

  modules = internal.config.modules or []

  # Find and load modules
  pkg = internal.retriever.retrieve('package')
  internal.modules = getAxiomModules(pkg, internal.config.blacklist)
  internal.modules = _.union internal.modules, modules

  # Require each axiom module.
  # Pass to load.
  for moduleName in internal.modules
    # In case we have passed in a blacklisted module
    continue if moduleName in internal.config.blacklist

    moduleDef = internal.retriever.retrieveExtension(moduleName)
    load moduleName, moduleDef

  for moduleName, moduleLocation of internal.config.appExtensions
    moduleDef = internal.retriever.retrieve(moduleLocation)
    load moduleName, moduleDef
