mockery = require 'mockery'

module.exports =
  disable: ->
    mockery.disable()

  enable: ->
    mockery.enable
      warnOnReplace: false,
      warnOnUnregistered: false

    mockery.registerMock 'axiom-base',
      services:
        runtime: (args, next) ->
          next null, {message: 'axiom-base'}