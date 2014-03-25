_ = require 'lodash'

getAxiomModules = require '../getAxiomModules'

internal = require './internal'
load = require './load'
logger = require 'torch'

module.exports = (config, retriever) ->

  # yay, logging
  core = require '../core'
  core.wireUpLoggers(config?.loggers)
  core.log.coreEntry 'init', {config, retriever}

  modules = config?.modules or []

  # override base retriever properties with provided retriever
  internal.retriever = _.merge {}, require('../retriever'), retriever

  # Attempt to load a global 'axiom.*' file from the project root
  try
    _.merge internal.config, internal.retriever.retrieve('axiom')

  # Merge in any programatically-passed config object
  _.merge internal.config, config

  # Find and load modules
  pkg = internal.retriever.retrieve('package')
  internal.modules = getAxiomModules(pkg, internal.config.blacklist)
  internal.modules = _.union internal.modules, modules

  # Load the 'axiom-base'
  unless 'base' in internal.modules
    load 'base', internal.retriever.retrieveExtension 'base'

  # Require each axiom module.
  # Pass to load.
  for moduleName in internal.modules
    # In case we have passed in a blacklisted module
    continue if moduleName in internal.config.blacklist

    moduleDef = internal.retriever.retrieveExtension(moduleName)
    load moduleName, moduleDef

  for moduleName, moduleLocation of config.appExtensions
    moduleDef = internal.retriever.retrieve(moduleLocation)
    load moduleName, moduleDef
