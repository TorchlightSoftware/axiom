{join} = require 'path'
logger = require 'torch'

module.exports = ->
  retriever =

    # a mock of packages returned
    packages: {
      package:
        dependencies:
          'axiom-server': '*'
      node_modules:
        'axiom-base':
          {
            services:
              runtime: (args, next) ->
                next null, {message: 'axiom-base'}
          }
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
