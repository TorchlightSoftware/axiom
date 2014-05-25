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

class TimeoutError extends AxiomError
  name: 'AxiomError/TimeoutError'

  constructor: (context, start) ->
    {channel} = context
    message = "Request timed out on channel: '#{channel}'"

    super message, context, start

module.exports = {NoRespondersError, AmbiguousRespondersError, TimeoutError}
