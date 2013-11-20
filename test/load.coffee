should = require 'should'
logger = require 'torch'

core = require '..'


describe 'core.load', ->
  afterEach ->
    core.reset()


  it 'should load a default base', (done) ->
    module =
      services:
        run: (args, done) ->
          done null, {status: 'success'}

    core.load 'server', module
    core.request 'server.run', {}, (err, data) ->
      should.not.exist err
      should.exist data
      data.should.eql {status: 'success'}

      done()


  it 'should load a referenced base', (done) ->
    core.load 'base', {
      services:
        lifecycle: (args, done) ->
          done null, args.args
    }

    core.load 'server', {
      config:
        run:
          base: 'lifecycle'
    }

    data = {x: 111}
    core.request 'server.run', data, (err, result) ->
      should.not.exist err
      should.exist result
      result.should.eql data

      done()


  it 'should load a law service', (done) ->
    module =
      services:
        run:
          service: (args, done) ->
            done null, {status: 'success'}

    core.load 'server', module
    core.request 'server.run', {}, (err, data) ->
      should.not.exist err
      should.exist data
      data.should.eql {status: 'success'}

      done()


  it 'should load an aliased namespace', (done) ->
    module =
      config:
        run:
          extends: 'server'
      services:
        'run/prepare': (args, done) ->
          done null, {status: 'prepared'}

    core.load 'extension', module
    core.request 'server.run/prepare', {}, (err, data) ->
      should.not.exist err
      should.exist data
      data.should.eql {status: 'prepared'}

      done()


  it 'should receive axiom/config in context', (done) ->
    robot =
      config:
        crushLikeBug:
          strength: 5
      services:
        crushLikeBug: (args, fin) ->
          should.exist @axiom, 'expected axiom in context'

          @axiom.should.have.keys ['init', 'reset', 'load', 'request', 'delegate',
                                    'respond', 'send', 'listen', 'log']

          should.exist @config, 'expected config in context'
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
