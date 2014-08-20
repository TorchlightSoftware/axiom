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
    {channel} = context
    message = "Request timed out on channel: '#{channel}'"

    super message, context, start

class DelegateTimeoutError extends AxiomError
  name: 'AxiomError/RequestTimeoutError'

  constructor: (context, start) ->
    {channel, responderId} = context
    message = "Responder with id '#{responderId}' timed out on channel: '#{channel}'"

    super message, context, start


class ErrorCollection extends AxiomError
  name: 'AxiomError/ErrorCollection'

  constructor: (context, start) ->
    {channel, errors} = context

    errArray = for responder, error of errors
      error.stack
    message = "Received errors from channel '#{channel}':\n#{errArray.join '\n'}"

    super message, context, start

module.exports = {NoRespondersError, AmbiguousRespondersError,
  RequestTimeoutError, DelegateTimeoutError, ErrorCollection}
