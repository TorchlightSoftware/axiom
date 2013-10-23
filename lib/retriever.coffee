{join} = require 'path'
{findProjRoot} = require './util'


# Should be an object that exposes:
# - Project-relative path helper
# - General project-relative loader
# - Project-relative Axiom extension loader
module.exports = retriever =
  # The root of the project.
  # Determined relative to the value of process.cwd()
  # in the calling context of 'makeLoader'.
  projRoot: findProjRoot()

  # Relative path construction helper.
  # Creates paths prefixed by the value of 'loader.projRoot'.
  rel: (args...) ->
    join(retriever.projRoot, args...)

  # Calls 'require' on a subpath constructed by prefixing
  # 'path' with the path to the project root.
  # Returns 'undefined' if no module was found.
  retrieve: (args...) ->
    try
      return require retriever.rel(args...)
    catch err
      throw err unless err.code is 'MODULE_NOT_FOUND'

  # Require an Axiom extension module with name 'axiom-<name>'
  # installed in the 'node_modules' folder of the project root.
  retrieveExtension: (name) ->
    retriever.retrieve 'node_modules', "axiom-#{name}"
