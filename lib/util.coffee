fs = require 'fs'
{join, dirname} = require 'path'


findProjRoot = ->
  # Walk backwards, looking for 'package.json' or equivalent
  klaw = (dir) ->
    # If we hit root, we've failed to find any 'package.*'.
    return undefined if dir is '/'

    try
      # If this doesn't throw, then it exists.
      # We've found a 'package.*', so we're done!
      resolved = require.resolve join(dir, 'package')
      return dir
    catch err
      # No luck here, so walk back up and check the parent directory
      return klaw dirname(dir)

  # Initial call using the current working directory
  return klaw process.cwd()


# Should make an object that exposes:
# - Project-relative path helper
# - General project-relative loader
# - Project-relative Axiom extension loader
makeLoader = ->
  loader =
    # The root of the project.
    # Determined relative to the value of process.cwd()
    # in the calling context of 'makeLoader'.
    projRoot: findProjRoot()

    # Relative path construction helper.
    # Creates paths prefixed by the value of 'loader.projRoot'.
    rel: (args...) ->
      join(loader.projRoot, args...)

    # Calls 'require' on a subpath constructed by prefixing
    # 'path' with the path to the project root.
    # Returns 'undefined' if no module was found.
    load: (args...) ->
      try
        return require loader.rel(args...)
      catch err
        throw err unless err.code is 'MODULE_NOT_FOUND'

    # Require an Axiom extension module with name 'axiom-<name>'
    # installed in the 'node_modules' folder of the project root.
    loadExtension: (name) ->
      loader.load 'node_modules', "axiom-#{name}"

  return loader


module.exports =
  findProjRoot: findProjRoot
  makeLoader: makeLoader