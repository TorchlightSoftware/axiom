# This is an individual extension configuration.  Since it exports
# a function, Axiom will call that function with the general
# configuration section.

# The returned values will be available within the extension implementation.
# Refer to the documentation for a specific extension to know what
# values are supported and what effect they have.
module.exports = (general) ->

  # pass through a value from the general config
  return {
    port: general.serverPort
  }
