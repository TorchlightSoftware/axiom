internal = require './core/internal'

core =
  init: require('./core/init')

  reset: require('./core/reset')

  load: require('./core/load')

  # used to load processes from Protocol
  loadProcess: require('./core/loadProcess')

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

  # For logging on the channel 'axiom.log'
  log: require('./core/log')

  # Sets up an array of log writers.
  wireUpLoggers: require('./core/wireUpLoggers')

  link: require('./core/link')

module.exports = core
