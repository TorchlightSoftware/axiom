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


module.exports =
  findProjRoot: findProjRoot
