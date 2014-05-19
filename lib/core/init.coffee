_ = require 'lodash'

internal = require './internal'
load = require './load'
logger = require 'torch'

module.exports = (config, retriever) ->

  # override base retriever properties with provided retriever
  internal.retriever = _.merge {}, internal.retriever, retriever
  Object.freeze internal.retriever

  # Attempt to load the project's export as a config
  try
    projectConfig = internal.retriever.retrieve('')
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

  # Load the system protocol.
  load 'protocol', internal.config.protocol if internal.config.protocol?

  # Load each extension.
  for extensionName, extensionLocation of internal.config.extensions
    load extensionName, extensionLocation
