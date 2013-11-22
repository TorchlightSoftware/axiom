path = require 'path'
should = require 'should'
logger = require 'torch'
{spawn, exec} = require 'child_process'

rel = (name) -> path.join __dirname, name

command = rel '../bin/axiom'

sampleProject = rel '../sample/project2'

cliRun = (args) ->
  cli = spawn command, args, {cwd: sampleProject}
  output = []
  ['stdout', 'stderr'].forEach (source) ->
    cli[source].setEncoding 'utf8'
    cli[source].on 'data', logger.yellow
    cli[source].on 'data', (message) -> output.push({source, message})

  return {cli, output}

removeTimestamps = (output) ->
  # For each {source, message} in the collected output
  output.map ({source, message}) ->

    # If prefixed with a timestamp
    if /\[.*\].*/.test(message)

      # Slice off the timestamp prefix
      message = message.slice(34)

    return {source, message}

tests = [
  description: "should fail with a help message if missing 'moduleName'"
  args: []
  expected: [
    source: 'stdout'
    message: "Missing required positional argument: 'moduleName'\n"
   ,
    source: 'stdout'
    message: 'Usage: axiom <moduleName> <serviceName> [<--arg> <value> ...]\n\n\n'
  ]
 ,
  description: "should fail with a help message if missing 'serviceName'"
  args: ['hello']
  expected: [
    source: 'stdout'
    message: "Missing required positional argument: 'serviceName'\n"
   ,
    source: 'stdout'
    message: 'Usage: axiom <moduleName> <serviceName> [<--arg> <value> ...]\n\n\n'
  ]
 ,
  description: 'should start the server'
  args: ['hello', 'world']
  expected: [{source: 'stdout', message: 'Hello, world!\n'}]
]

logTests = [
  description: "should accept '--log=info'"
  args: ['hello', 'world', '--log=info']
  expected: [
    source: 'stdout'
    message: "Calling 'core.init' with args: { config: undefined, retriever: undefined }\n"
   ,
    source: 'stdout'
    message: "Calling 'core.load' with args: { moduleName: 'base' }\n"
   ,
    source: 'stdout'
    message: "Calling 'core.load' with args: { moduleName: 'hello' }\n"
   ,
    source: 'stdout'
    message: "Calling 'core.respond' with args: { channel: 'hello.world' }\n"
   ,
    source: 'stdout'
    message: "Calling 'core.request' with args: { channel: 'hello.world', data: { log: 'info' } }\n"
   ,
    source: 'stdout'
    message: "Calling 'core.send' with args: { channel: 'hello.world', data: { log: 'info' } }\n"
   ,
    source: 'stdout'
    message: 'Hello, world!\n'
  ]
 ,
  description: "should accept '--log=debug'"
  args: ['hello', 'world', '--log=debug']
  expected: [
    source: 'stdout'
    message: "Calling 'core.listen' with args: { channel: 'axiom.log', topic: 'debug' }\n"
   ,
    source: 'stdout'
    message: "Calling 'core.init' with args: { config: undefined, retriever: undefined }\n"
   ,
    source: 'stdout'
    message: "Calling 'core.load' with args: { moduleName: 'base' }\n"
   ,
    source: 'stdout'
    message: "Calling 'core.load' with args: { moduleName: 'hello' }\n"
   ,
    source: 'stdout'
    message: "Calling 'core.respond' with args: { channel: 'hello.world' }\n"
   ,
    source: 'stdout'
    message: "Calling 'core.request' with args: { channel: 'hello.world', data: { log: 'debug' } }\n"
   ,
    source: 'stdout'
    message: "Calling 'core.send' with args: { channel: 'hello.world', data: { log: 'debug' } }\n"
   ,
    source: 'stdout'
    message: 'Hello, world!\n'
  ]
]

describe 'cli', ->
  @timeout 2000

  # General tests
  for test in tests
    do (test) ->
      # Given a set of arguments
      {description, args, expected} = test

      it description, (done) ->
        # When we run the CLI with those arguments
        {cli, output} = cliRun args

        cli.on 'close', ->
          # Teh result should be what we expect
          output.should.eql expected

          done()

  # Log-level tests
  for test in logTests
    do (test) ->
      # Given an expected sequence of unprefixed log statements
      {description, args, expected} = test

      it description, (done) ->
        # When we run the CLI at a given log level
        {cli, output} = cliRun args

        cli.on 'close', ->
          # The result should be what we expect, after
          # stripping the prefixed timestamps.
          removeTimestamps(output).should.eql expected

          done()
