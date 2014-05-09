{join} = require 'path'
logger = require 'torch'
_ = require 'lodash'

retriever =

  # a mock of packages returned
  packages: {

    # core axiom config
    axiom: {}

    # extension configs
    config: {}

    # package.json
    package: {}

    # put module name, export contents as key/value
    node_modules: {}
  }

  root: ''
  rel: (args...) ->
    join @root, args...

  retrieve: (args...) ->
    args = _(args).map((n)->n.split '/').flatten().value()

    result = @packages
    for path in args
      result = result[path]
    return result

  retrieveExtension: (name) ->
    @retrieve 'node_modules', "axiom-#{name}"

module.exports = -> _.cloneDeep retriever
