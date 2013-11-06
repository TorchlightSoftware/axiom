path = require 'path'

timers = require 'timers'
logger = require 'torch'

law = require 'law'
uuid = require 'uuid'
async = require 'async'
_ = require 'lodash'

bus = require './bus'
getAxiomModules = require './getAxiomModules'
internal = require './core/internal'


core =
  init: (config, retriever) ->
    core.reset()
    modules = config?.modules or []
    internal.retriever = retriever or require('./retriever')

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
      core.load 'base', internal.retriever.retrieveExtension 'base'

    # Require each axiom module.
    # Pass to load.
    for moduleName in internal.modules
      # In case we have passed in a blacklisted module
      continue if moduleName in internal.config.blacklist

      moduleDef = internal.retriever.retrieveExtension(moduleName)
      core.load moduleName, moduleDef

  reset: ->
    internal.reset()

  load: require('./core/load')

  # Subscribe to a response address.
  # Publish a message, with a response address in the envelope.
  # Time out based on axiom config.
  request: require('./core/request')

  delegate: require('./core/delegate')

  # Sends acknowledgement, error, completion to replyTo channels
  respond: require('./core/respond')

  # Just send the message
  send: require('./core/send')

  # Just listen
  listen: require('./core/listen')

  # For sending interrupts
  signal: require('./core/signal')


module.exports = core
