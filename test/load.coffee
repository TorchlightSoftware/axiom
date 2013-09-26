should = require 'should'
logger = require 'torch'

load = require '../lib/load'
bus = require '../lib/bus'

describe 'load', ->
  afterEach ->
    bus.utils.reset()

  tests = [
      description: 'a default base'
      module:
        name: 'server'
        services:
          run: (args, done) ->
            #logger.blue 'inside run service', arguments
            done null, {status: "success"}
      input: ['server.run', {foo: 1, bar: 2}]
      output: ['server.run.success', {status: "success"}]
    ,
      description: 'a referenced base'
      module:
        name: 'server'
        config:
          run:
            base: 'lifecycle'
      input: ['server.run', {foo: 1, bar: 2}]
      output: ['base.run', {foo: 1, bar: 2}]
  ]

  for test in tests
    do (test) ->
      {description, module, input, output} = test
      it description, (done) ->
        load module, (err, result) ->
          bus.subscribe
            channel: output[0]
            callback: (result) ->
              should.exist result
              result.should.eql output[1]
              done()

          bus.publish
            channel: input[0]
            data: input[1]
