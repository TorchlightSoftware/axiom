should = require 'should'
logger = require 'torch'
uuid = require 'uuid'

mockery = require './mockery'
bus = require '../lib/bus'
core = require '../lib/core'


describe 'load', ->
  afterEach ->
    #mockery.disable()
    core.reset()

  beforeEach ->
    #mockery.enable()
    #core.init()

#   tests = [
#       description: 'a default base'
#       module:
#         name: 'server'
#         services:
#           run: (args, done) ->
#             done null, {status: "success"}
#       input:
#         channel: 'server.run'
#       output:
#         channel: 'server.run'
#         topic: 'success.#'
#         data: {status: "success"}
#     ,
#       description: 'a referenced base'
#       module:
#         name: 'server'
#         config:
#           run:
#             base: 'lifecycle'
#             foo: 1
#             bar: 2
#       input:
#         channel: 'server.run'
#         data: {baz: 45}
#       output:
#         channel: 'base.lifecycle'
#         topic: 'request.#'
#         data:
#           args:
#             {baz: 45}
#           config:
#             base: 'lifecycle'
#             foo: 1
#             bar: 2
#     ,
#       description: 'a law service'
#       module:
#         name: 'server'
#         services:
#           run:
#             service: (args, done) ->
#               done null, {status: "success"}
#       input:
#         channel: 'server.run'
#         data: {foo: 1, bar: 2}
#       output:
#         channel: 'server.run'
#         topic: 'success.#'
#         data: {status: "success"}
#     ,
#       description: 'an aliased namespace'
#       module:
#         name: 'implementation'
#         config:
#           run:
#             extends: 'server'
#         services:
#           "run/prepare": (args, done) ->
#             done null, {status: "prepared"}
#       input:
#         channel: 'server.run/prepare'
#         data: {}
#       output:
#         channel: 'server.run/prepare'
#         topic: 'success.#'
#         data: {status: "prepared"}
#   ]

#   for test in tests
#     do (test) ->
#       {description, module, input, output} = test
#       it description, (done) ->
#         core.load module.name, module

#         id = uuid.v1()

#         replyTo =
#           channel: input.channel
#           topic:
#             success: "success.#{id}"
#             error: "error.#{id}"

#         bus.subscribe
#           channel: output.channel
#           topic: output.topic
#           callback: (result) ->
#             should.exist result
#             result.should.include output.data
#             done()

#         bus.publish
#           channel: input.channel
#           topic: "request.#{id}"
#           data: input.data
#           replyTo: replyTo

  it 'should receive config in context', (done) ->
    robot =
      config:
        crushLikeBug:
          strength: 5
      services:
        crushLikeBug: (args, fin) ->
          should.exist @config
          @config.should.eql {
            strength: 5
          }
          fin()

    core.load "robot", robot
    core.request "robot.crushLikeBug", {}, done

  it 'should share context between services in a namespace', (done) ->
    server =
      config:
        run:
          port: 4000

      services:
        "run/prepare": (args, fin) ->
          @foo = 7
          fin()

        "run/boot": (args, fin) ->
          should.exist @foo, 'expected foo in context'
          @foo.should.eql 7
          fin()

    core.load "server", server
    core.request "server.run/prepare", {}, (err, result) ->
      should.not.exist err
      core.request "server.run/boot", {}, done

  it 'should not share context between services in different namespaces', (done) ->
    server =
      config:
        run:
          port: 4000
        test:
          timeout: 200

      services:
        "run/prepare": (args, fin) ->
          should.exist @config?.port, 'expected port in context'
          @config.port.should.eql 4000
          @foo = 7
          fin()

        "test/prepare": (args, fin) ->
          should.exist @config?.timeout, 'expected timeout in context'
          @config.timeout.should.eql 200
          should.not.exist @foo
          fin()

    core.load "server", server
    core.request "server.run/prepare", {}, (err, result) ->
      should.not.exist err
      core.request "server.test/prepare", {}, done
