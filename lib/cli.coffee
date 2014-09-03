#!/usr/bin/env coffee

# NOTE: Shouldn't be necessary to run this file directly, use bin/axiom instead.
logger = require 'torch'
optimist = require 'optimist'
_ = require 'lodash'
moment = require 'moment'

core = require '..'

optimist.usage 'Usage: axiom <extensionName> <serviceName> [<--arg> <value> ...]'
parsed = optimist.options {}

# Should correspond to an installed NPM module
# named 'axiom-<extensionName>' exposing service 'serviceName'
[extensionName, serviceName] = parsed.argv._

# TODO: Change this to instead alert specific error and print usage information
unless extensionName
  logger.red "Missing required argument: 'extensionName'"
  logger.yellow parsed.help()
  return

unless serviceName
  logger.red "Missing required argument: 'serviceName'"
  logger.yellow parsed.help()
  return

if /test/i.test serviceName
  process.env.NODE_ENV = 'test'

# Anything with the prefix 'axiom' extends the config.  E.G. `axiom server run --axiom.foo=true`
{axiom} = parsed.argv

# Extract the remaining args for the service
toOmit = [
  # Special optimist properties
  '_', '$0'
  # Axiom config arguments
  'axiom'
]
args = _.omit parsed.argv, toOmit

config = _.merge {
  loggers: [{writer: 'console', level: args.log or 'info'}]
}, axiom

core.init(config, null, args)

channel = "#{extensionName}.#{serviceName}"

core.request channel, {}, (err, results) ->
  if err?
    logger.red err.stack
  else
    logger.green 'Success!'
