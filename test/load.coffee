should = require 'should'
logger = require 'torch'

core = require '..'

describe 'core.load', ->
  beforeEach ->
    core.wireUpLoggers [{writer: 'console', level: 'info'}]

  afterEach ->
    core.reset()

  it 'should load a service', (done) ->
    server =
      services:
        run: (args, done) ->
          done null, {status: 'success'}

    core.load 'server', server
    core.request 'server.run', {}, (err, data) ->
      should.not.exist err
      should.exist data
      data.should.eql {status: 'success'}

      done()

  it 'should load a law service', (done) ->
    server =
      services:
        run:
          service: (args, done) ->
            done null, {status: 'success'}

    core.load 'server', server
    core.request 'server.run', {}, (err, data) ->
      should.not.exist err
      should.exist data
      data.should.eql {status: 'success'}

      done()

  it 'should alias services', (done) ->
    connectExtension =
      attachments:
        startServer: ['server.run/load']
      services:
        startServer: (args, fin) ->
          fin()

    core.load 'connect', connectExtension
    core.request 'server.run/load', {}, done

  it 'should receive axiom/config in context', (done) ->
    robot =
      config:
        strength: 5
      services:
        crushLikeBug: (args, fin) ->
          should.exist @axiom, 'expected axiom in context'
          should.exist @config, 'expected config in context'
          @config.should.eql robot.config

          fin()

    core.load "robot", robot
    core.request "robot.crushLikeBug", {}, done

  describe 'protocol', ->

    it 'should create an agent process', (done) ->
      protocol =
        protocol:
          server:
            run:
              type: 'agent'
              signals:
                start: ['load']
                stop: ['unload']

      # if this doesn't get called our test will time out
      loader = (args, fin) ->
        done()

      unloaded = false
      unloader = (args, fin) ->
        unloaded = true
        fin()

      core.load 'protocol', protocol
      core.respond 'server.run/load', loader
      core.respond 'server.run/unload', unloader
      core.request 'server.run', {}, ->
        if unloaded
          throw new Error 'agent should not unload'

    it 'should create a task process', (done) ->
      protocol =
        protocol:
          server:
            run:
              type: 'task'
              signals:
                start: ['load']
                stop: ['unload']

      # if this doesn't get called our test will time out
      unloaded = false
      unloader = (args, fin) ->
        unloaded = true
        fin()

      core.load 'protocol', protocol
      core.respond 'server.run/unload', unloader
      core.request 'server.run', {}, ->
        unloaded.should.eql true
        done()
