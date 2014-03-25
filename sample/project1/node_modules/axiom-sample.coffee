module.exports =
  name: 'sample'
  config:
    whatsMyContext:
      x: 2
      y: 3
      translateMe: 'hello'
  services:
    echo: (args, done) ->
      done null, args
    whatsMyContext: (args, done) ->
      done null, @config