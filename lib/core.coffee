{readdirSync} = require 'fs'
{basename} = require 'path'

# read all the files in the core directory and expose them as API functions
files = readdirSync __dirname + '/core'
api = {}
for fname in files
  name = basename fname, '.coffee'
  api[name] = require "./core/#{name}"

module.exports = api
