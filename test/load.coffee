should = require 'should'
logger = require 'torch'

load = require '../lib/load'
postal = require('postal')()
bus = postal.channel 'axiom'

describe 'load', ->
  afterEach ->
    postal.utils.reset()

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
          bus.subscribe output[0], (result) ->
            should.exist result
            result.should.eql output[1]
            done()

          bus.publish input...
