{join} = require 'path'
findProjectRoot = require './findProjectRoot'

# Should be an object that exposes:
# - Project-relative path helper
# - General project-relative loader
# - Project-relative Axiom extension loader
module.exports = Object.freeze

  # The root of the project.
  # Determined relative to the value of process.cwd()
  # in the calling context of 'makeLoader'.
  root: findProjectRoot(process.cwd())

  # Relative path construction helper.
  # Creates paths prefixed by the value of 'loader.projectRoot'.
  rel: (args...) ->
    join(@root, args...)

  # Calls 'require' on a subpath constructed by prefixing
  # 'path' with the path to the project root.
  # Returns 'undefined' if no module was found.
  retrieve: (args...) ->
    require @rel(args...)

  # Require an Axiom extension module with name 'axiom-<name>'
  # installed in the 'node_modules' folder of the project root.
  retrieveExtension: (name) ->
    @retrieve 'node_modules', "axiom-#{name}"
