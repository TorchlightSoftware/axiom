module.exports =
  extends:
    printEnv: ['server.test/load', 'client.test/load']

  services:
    doStuff: (args, done) ->
      done null, {status: 'stuff is done'}

    printEnv: (args, done) ->
      @log.info {env: process.env.NODE_ENV}
      done()
