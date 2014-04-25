{join} = require 'path'
logger = require 'torch'

module.exports = ->
  retriever =

    # a mock of packages returned
    packages: {

      # core axiom config
      axiom: {}

      # extension configs
      axiom_configs: {}

      # package.json
      package: {}

      # put module name, export contents as key/value
      node_modules: {}
    }

    projectRoot: ''
    rel: (args...) ->
      join retriever.projectRoot, args...

    retrieve: (args...) ->
      #logger.yellow 'retrieving:', args
      result = retriever.packages
      for path in args
        result = result[path]
      return result

    retrieveExtension: (name) ->
      retriever.retrieve 'node_modules', "axiom-#{name}"

  return retriever
