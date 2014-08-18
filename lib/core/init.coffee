_ = require 'lodash'

internal = require './internal'
load = require './load'
logger = require 'torch'

module.exports = (config, retriever, args) ->

  # save command line args for merging with extension-specific configs
  internal.args = args

  # override base retriever properties with provided retriever
  internal.retriever = _.merge {}, internal.retriever, retriever
  Object.freeze internal.retriever

  # Attempt to load the project's export as a config
  loadError = null
  try
    projectConfig = internal.retriever.retrieve('')
    _.merge internal.config, projectConfig

  catch e # logger not initialize yet so just save the error

  # Merge in any programatically-passed config options
  _.merge internal.config, config
  Object.freeze internal.config

  # yay, logging
  core = require '../core'
  core.wireUpLoggers(internal.config.loggers)

  if e
    core.log.warning 'Error loading project config:', e.stack

  core.log.coreEntry 'init',
    config: internal.config
    retriever: internal.retriever

  # Load each extension.
  for extensionName, extensionLocation of internal.config.extensions
    load extensionName, extensionLocation

  # Configure routes
  for route in (internal.config.routes or [])
    if _.isArray(route)
      [relation, from, to] = route
    else
      {relation, from, to} = route

    switch relation
      when 'link'
        core.link from, to
