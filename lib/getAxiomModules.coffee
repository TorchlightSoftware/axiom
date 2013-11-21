_ = require 'lodash'
logger = require 'torch'

getKeys = (obj) ->
  if obj? then Object.keys(obj) else undefined

module.exports = (pkg, blacklist) ->

  dependencies = _.union getKeys(pkg?.dependencies), getKeys(pkg?.devDependencies)

  # Filter out non-axiom NPM modules
  axiomNpmModules = dependencies.filter (dep) -> /^axiom-\S\S*/.test dep

  # Remove the 'axiom-' prefix
  axiomModules = axiomNpmModules.map (m) -> m.slice('axiom-'.length)

  # We only want the axiom modules not blacklisted, so take the
  # set difference of 'axiomModules' \ 'blacklist'.
  axiomModules = _.difference axiomModules, blacklist

  return axiomModules
