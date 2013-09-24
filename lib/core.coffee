bus = require './bus'

module.exports =
  init: ->
    # require each axiom module
    # pass to load

  request: (channel, data, done) ->
    # subscribe to a response address
    # publish a message, with a response address in the envelope
    # time out based on axiom config

  delegate: (channel, data, done) ->
    # same as request, but for multiple recipients
    # ask each recipient to acknowledge receipt
    # wait until we receive a response from each recipient
    # time out based on axiom config - report timeouts for each recipient

  respond: (channel, handler) ->
    # can respond to request or delegate (or should we split this out?)
    # sends acknowledgement, error, completion to replyTo channels

  send: (channel, data) ->
    # just send the message

  listen: (channel, handler) ->
    # just listen

  signal: (channel, data) ->
    # for sending interrupts
