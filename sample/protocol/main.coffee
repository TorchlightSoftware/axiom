module.exports =

  # Extensions standardize technology configuration and integration.
  # They can be Public (require via npm),
  # or Private (require a package on the local fs).
  extensions:
    protocol: '*'
    connect: '*'
    fusionPower: require './extensions/workInProgress'

  # These settings are passed to all extension configurations,
  # and provide a way to distribute common values.
  config:
    serverPort: 4000
    apiPort: 4001

  routes: [
    # rel,       from,           to
    ['link', 'connect.status', 'fusionPower.status']
  ]
