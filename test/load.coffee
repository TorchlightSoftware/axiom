should = require 'should'
logger = require 'torch'

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
            foo: 1
            bar: 2
      input:
        channel: 'server.run'
        topic: 'whatever'
        data: {baz: 45}
      output:
        channel: 'base.lifecycle'
        topic: 'request.#'
        data:
          args:
            {baz: 45}
          config:
            base: 'lifecycle'
            foo: 1
            bar: 2
    ,
      description: 'a law service'
      module:
        name: 'server'
        services:
          run:
            service: (args, done) ->
              done null, {status: "success"}
      input:
        channel: 'server.run'
        topic: 'runServer'
        data: {foo: 1, bar: 2}
      output:
        channel: 'server.run.success'
        topic: 'runServer'
        data: {status: "success"}
  ]

  for test in tests
    do (test) ->
      {description, module, input, output} = test
      it description, (done) ->
        core.load module.name, module

        replyTo =
          channel: output.channel
          topic:
            success: output.topic

        bus.subscribe
          channel: output.channel
          topic: output.topic
          callback: (result) ->
            should.exist result
            result.should.include output.data
            done()

        bus.publish
          channel: input.channel
          data: input.data
          topic: "request.#{input.topic}"
          replyTo: replyTo
