module.exports =
  config:

    run:
      type: 'extension'
      target: 'server.run'

    '*':
      port: 4000
      ssl: false

      allowAll: true
      options: [
        "compress"
        "responseTime"
        "favicon"
        "staticCache"
        "query"
        "cookieParser"
      ]

      static: ['app/public']

#  SERVER INTERFACE:
#  start: ['starting', 'online', 'verifyState']
#  stop: ['stopping', 'offline', 'verifyState']

  services:
    starting:
      dependencies:
        lib: ['connect', 'http']
        axiom: ['config', 'resolve']

      service: (args, done, {
        lib: {connect, http}
        axiom: {config, resolve}}
      ) ->

        app = connect()

        if config.allowAll
          app.use (req, res, next) ->
            res.setHeader "Access-Control-Allow-Origin", "*"
            next()

        for option in config.options
          app.use connect[option]()

        if config.static
          for loc in config.static
            app.use connect.static resolve(loc)

        services.createServer {app}, done

    createServer:
      dependencies:
        lib: ['http', 'https', 'fs']
        axiom: ['config']

      service: (args, done, {
        lib: {http, https, fs}
        axiom: {config}}
      ) ->

        read = (file) -> fs.readFileSync file, 'utf8'

        if config.ssl

          # read cert files
          ca = config.ssl.ca || []
          options =
            key: read config.ssl.key
            cert: read config.ssl.cert
            ca: ca.map read

          # create server with ssl
          server = https.createServer(options, app).listen config.port, done

          # http server to redirect to https
          if (config.port is config.app.port) and config.app.ssl.redirectFrom?
            redirect = (req, res) ->
              redirectTarget = "https://#{req.headers.host}#{req.url}"
              res.writeHead 301, {
                "Location": redirectTarget
              }
              res.end()
            redirectServer = http.createServer(redirect).listen config.app.ssl.redirectFrom

          return server

        else
          http.createServer(app).listen config.port, done
