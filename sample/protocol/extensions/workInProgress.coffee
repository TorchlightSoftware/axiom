module.exports =
  services:
    doStuff: (args, done) ->
      done null, {status: 'stuff is done'}
