_ = require 'lodash'

module.exports = (pkg, blacklist) ->

  dependencies = _.union pkg?.dependencies, pkg?.devDependencies

  # Filter out non-axiom NPM modules
  axiomNpmModules = dependencies.filter (dep) -> /^axiom-\S\S*/.test dep

  # Remove the 'axiom-' prefix
  axiomModules = axiomNpmModules.map (m) -> m.slice('axiom-'.length)

  # We only want the axiom modules not blacklisted, so take the
  # set difference of 'axiomModules' \ 'blacklist'.
  axiomModules = _.difference axiomModules, blacklist

  return axiomModules
