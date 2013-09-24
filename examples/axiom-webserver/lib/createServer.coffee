{join} = require 'path'
fs = require 'fs'

http = require 'http'
https = require 'https'

read = (file) -> fs.readFileSync file, 'utf8'

module.exports = (port, app, done) ->
  app ?= ->
  done ?= ->

  if config.app.ssl

    # read cert files
    ca = config.app.ssl.ca || []
    options =
      key: read config.app.ssl.key
      cert: read config.app.ssl.cert
      ca: ca.map read

    # create server with ssl
    server = https.createServer(options, app).listen port, done

    #http server to redirect to https
    if (port is config.app.port) and config.app.ssl.redirectFrom?
      redirect = (req, res) ->
        redirectTarget = "https://#{req.headers.host}#{req.url}"
        res.writeHead 301, {
          "Location": redirectTarget
        }
        res.end()
      redirectServer = http.createServer(redirect).listen config.app.ssl.redirectFrom

    return server

  else
    http.createServer(app).listen port, done
