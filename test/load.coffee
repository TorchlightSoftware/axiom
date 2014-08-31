should = require 'should'
logger = require 'torch'
mockRetriever = require './helpers/mockRetriever'

core = require '..'

describe 'core.load', ->
  beforeEach (done) ->
    core.reset (err) ->
      core.init {}, mockRetriever()
      core.wireUpLoggers [{writer: 'console', level: 'info'}]
      done(err)

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

  it 'should extend the protocol', (done) ->
    connectExtension =
      extends:
        startServer: ['server.run/load']
      services:
        startServer: (args, fin) ->
          fin()

    core.load 'connect', connectExtension
    core.request 'server.run/load', {}, done

  it 'should control the protocol', (done) ->
    mochaExtension =
      controls:
        loadBeforeStep: 'server.test/before' #2

    otherExtension =
      extends:
        setupOther: ['server.test/before'] #3
      services:
        setupOther: (args, fin) -> #4
          fin()
          done()

    core.load 'mocha', mochaExtension
    core.load 'other', otherExtension
    core.request 'mocha.loadBeforeStep', {}, -> #1

  it 'should receive axiom utils in context', (done) ->
    robot =
      config:
        strength: 5
      services:
        crushLikeBug: (args, fin) ->
          @should.have.keys [
            'extensionName'
            'serviceName'
            'config'
            'errorTypes'
            'systemConfig'
            'appUtils'
            'appRetriever'
            'log'
            'request'
            'delegate'
            'respond'
            'respondOnce'
            'send'
            'listen'
            'root'
            'rel'
            'retrieve'
          ]

          @config.should.eql robot.config

          fin()

    core.load "robot", robot
    core.request "robot.crushLikeBug", {}, done

  it "should limit an extension's messages to its namespace", (done) ->
    robot =
      services:
        crushLikeBug: (args, fin) ->
          @send 'reportStatus', {status: 'success'}
          fin()

    core.load 'robot', robot
    core.listen 'robot.reportStatus', '#', (err, result) ->
      done()
    core.request 'robot.crushLikeBug', {}, ->

  it "should limit an extension's retriever to its namespace", (done) ->
    robot =
      services:
        crushLikeBug: (args, fin) ->
          path = @rel('foo/bar')
          path.should.eql 'domain/robot/foo/bar'
          fin()

    core.load 'robot', robot
    core.request 'robot.crushLikeBug', {}, done

  it 'should attach the extension name to services', (done) ->
    robot =
      services:
        crushLikeBug: (args, fin) ->
          fin()

    core.load "robot", robot
    core.send "robot.crushLikeBug", {}
    core.listen 'robot.crushLikeBug', 'success.#', (err, envelope) ->
      envelope.extension.should.eql 'robot'
      done()

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

    it 'should call unload on a task process', (done) ->
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

    it 'should pass unload args through stages', (done) ->

      protocol =
        protocol:
          server:
            run:
              type: 'task'
              signals:
                start: ['load', 'link']

        extends:
          loader: ['server.run/load']
          linker: ['server.run/link']

        services:
          loader: (args, fin) ->
            args.should.eql {a: 1}
            fin null, {b: 2}

          linker: (args, fin) ->
            args.should.eql {a: 1, b: 2}
            fin null, {c: 3}

      core.load 'protocol', protocol
      core.request 'server.run', {a: 1}, (err, result) ->
        should.not.exist err, 'expected no err'
        should.exist result, 'expected result'
        result.should.eql
          __delegation_result: true
          __input: {a: 1}
          protocol: {a: 1, b: 2, c: 3}
        done()

    it 'should pass proper args when a stage is skipped', (done) ->

      protocol =
        protocol:
          server:
            run:
              type: 'task'
              signals:
                start: ['load', 'link']

        extends:
          linker: ['server.run/link']

        services:
          linker: (args, fin) ->
            args.should.eql {a: 1}
            fin null, {c: 3}

      core.load 'protocol', protocol
      core.request 'server.run', {a: 1}, (err, result) ->
        should.not.exist err, 'expected no err'
        should.exist result, 'expected result'
        result.should.eql
          __delegation_result: true
          __input: {a: 1}
          protocol: {a: 1, c: 3}
        done()

    it 'should call unload when an agent is killed', (done) ->
      protocol =
        protocol:
          server:
            run:
              type: 'agent'
              signals:
                stop: ['unload']

        extends:
          unloader: ['server.run/unload']

        services:

          # if this doesn't get called our test will time out
          unloader: (args, fin) ->
            fin()
            done()

      core.load 'protocol', protocol
      core.request 'server.run', {}, ->
        core.delegate 'system.kill', {}, ->

    it 'should pass "unload" args from "load"', (done) ->
      protocol =
        protocol:
          server:
            run:
              type: 'task'
              signals:
                start: ['load']
                stop: ['unload']

        extends:
          loader: ['server.run/load']
          unloader: ['server.run/unload']

        services:
          loader: (args, fin) ->
            args.should.eql {a: 1}
            fin null, {b: 2}

          unloader: (args, fin) ->
            args.should.eql {a: 1, b: 2}
            fin null, {c: 3}

      core.load 'protocol', protocol
      core.request 'server.run', {a: 1}, (err, result) ->
        should.not.exist err, 'expected no err'
        should.exist result, 'expected result'
        done()
