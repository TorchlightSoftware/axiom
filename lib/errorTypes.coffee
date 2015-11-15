error = require 'tea-error'

AxiomError = error 'AxiomError'

class NoRespondersError extends AxiomError
  name: 'AxiomError/NoRespondersError'

  constructor: (context, start) ->
    {channel} = context
    message = "No responders for request: '#{channel}'"

    super message, context, start

class AmbiguousRespondersError extends AxiomError
  name: 'AxiomError/AmbiguousResondersError'

  constructor: (context, start) ->
    {channel, responders} = context
    message = "Ambiguous: #{responders.length} responders for request: '#{channel}'"

    super message, context, start

class RequestTimeoutError extends AxiomError
  name: 'AxiomError/RequestTimeoutError'

  constructor: (context, start) ->
    {channel, ms} = context
    time = if ms? then "after #{ms}ms " else ''
    message = "Request timed out #{time}on channel: '#{channel}'"

    super message, context, start

class DelegateTimeoutError extends AxiomError
  name: 'AxiomError/RequestTimeoutError'

  constructor: (context, start) ->
    {channel, responderId, ms} = context
    time = if ms? then "after #{ms}ms " else ''
    message = "Responder with id '#{responderId}' timed out #{time}on channel: '#{channel}'"

    super message, context, start


class ErrorCollection extends AxiomError
  name: 'AxiomError/ErrorCollection'

  constructor: (context, start) ->
    {channel, errors} = context

    errArray = (error.stack for responder, error of errors)
    message = "Received errors from channel '#{channel}':\n#{errArray.join '\n'}"

    super message, context, start

module.exports = {NoRespondersError, AmbiguousRespondersError,
  RequestTimeoutError, DelegateTimeoutError, ErrorCollection}
