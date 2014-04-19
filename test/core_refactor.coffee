should = require 'should'
logger = require 'torch'

core = require '..'

describe 'refactor', ->
  beforeEach ->
    core.wireUpLoggers [{writer: 'console', level: 'info'}]

  afterEach ->
    core.reset()

  describe 'config', ->

    it 'should be accessible within an extension', (done) ->
      serverExtension =
        config:
          port: 4000

        services:
          run: (args, fin) ->
            4000.should.eql @config.port
            fin()

      core.load 'server', serverExtension
      core.request 'server.run', {}, done

    it 'should not be accessible from another extension', (done) ->
      irrelevantExtension =
        config:
          irrelevantValue: 2

      serverExtension =
        services:
          run: (args, fin) ->
            @config.should.not.have.key 'irrelevantValue'
            fin()

      core.load 'irrelevant', irrelevantExtension
      core.load 'server', serverExtension
      core.request 'server.run', {}, done

  describe 'attachments', ->

    it 'should alias services', (done) ->
      connectExtension =
        attachments:
          startServer: ['server.run/load']
        services:
          startServer: (args, fin) ->
            fin()

      core.load 'connect', connectExtension
      core.request 'server.run/load', {}, done

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