internal = require './core/internal'

core =
  init: require('./core/init')

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
