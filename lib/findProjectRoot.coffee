{join, dirname} = require 'path'

# for a given directory:
# Walk backwards, looking for 'package.json' or equivalent
module.exports = findProjectRoot = (dir) ->

  # If we hit root, we've failed to find any 'package.*'.
  return undefined if (not dir) or (dir is '/')

  try

    # If this doesn't throw, then it exists.
    # We've found a 'package.*', so we're done!
    resolved = require.resolve join(dir, 'package')
    return dir

  catch err

    # No luck here, so walk back up and check the parent directory
    return findProjectRoot dirname(dir)
