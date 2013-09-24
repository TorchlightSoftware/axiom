module.exports =
  config:
    run:
      base: 'lifecycle'
      stages:
        start: ['prepare', 'boot', 'connect']
        stop: ['disconnect', 'shutdown', 'release']

    test:
      type: 'script'
      initialState: 'offline'

  #services:
    #'run/start':
      #service: (args, done, {axiom: {state}}) ->
        #phase.transition 'online'
        #done()

  #jargon: null
  #policy: null
  #resolvers: null
