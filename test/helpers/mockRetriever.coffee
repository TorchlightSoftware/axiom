{join} = require 'path'
logger = require 'torch'
_ = require 'lodash'

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
    join @projectRoot, args...

  retrieve: (args...) ->
    #logger.yellow 'retrieving:', args
    result = @packages
    for path in args
      result = result[path]
    return result

  retrieveExtension: (name) ->
    @retrieve 'node_modules', "axiom-#{name}"

module.exports = -> _.cloneDeep retriever
