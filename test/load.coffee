should = require 'should'
logger = require 'torch'

load = require '../lib/load'
bus = require '../lib/bus'
core = require '../lib/core'


describe 'load', ->
  afterEach ->
    bus.utils.reset()

  before ->
    core.init()

  tests = [
      description: 'a default base'
      module:
        name: 'server'
        services:
          run: (args, done) ->
            done null, {status: "success"}
      input:
        channel: 'server.run'
        topic: 'runServer'
        data: {foo: 1, bar: 2}
      output:
        channel: 'server.run.success'
        topic: 'runServer'
        data: {status: "success"}
    ,
      description: 'a referenced base'
      module:
        name: 'server'
        config:
          run:
            base: 'lifecycle'
      input:
        channel: 'server.run'
        topic: 'whatever'
        data: {foo: 1, bar: 2}
      output:
        channel: 'base.run'
        topic: 'request.#'
        data: {foo: 1, bar: 2}
  ]

  for test in tests
    do (test) ->
      {description, module, input, output} = test
      it description, (done) ->
        load module, (err, result) ->

          replyTo =
            channel: output.channel
            topic:
              success: output.topic

          bus.subscribe
            channel: output.channel
            topic: output.topic
            callback: (result) ->
              should.exist result
              result.should.eql output.data
              done()

          bus.publish
            channel: input.channel
            data: input.data
            topic: "request.#{input.topic}"
            replyTo: replyTo
