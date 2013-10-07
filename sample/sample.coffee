module.exports =
  name: 'sample'
  services:
    echo: (args, done) ->
      done null, args