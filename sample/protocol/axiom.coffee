module.exports =

  # These might be works in progress intended for future life
  # as a public extension.  Or, they might be intentially private
  # extensions.
  includeExtensions:
    app: require './workInProgress'

  # These might be broken extensions, which are included in node_modules
  # but which you don't want to load at the moment.
  excludeExtensions: ['foo', 'bar']

  # These settings are passed to all extension configurations,
  # and provide a way to distribute common values.
  general:
    serverPort: 4000
    apiPort: 4001
