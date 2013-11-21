path = require 'path'
should = require 'should'
logger = require 'torch'
{spawn, exec} = require 'child_process'

rel = (name) -> path.join __dirname, name

command = rel '../bin/axiom'

sampleProject = rel '../sample/project2'

cliRun = (args, cwd) ->
  cli = spawn command, args, {cwd}
  output = []
  ['stdout', 'stderr'].forEach (source) ->
    cli[source].setEncoding 'utf8'
    cli[source].on 'data', logger.yellow
    cli[source].on 'data', (message) -> output.push({source, message})

  return {cli, output}

describe 'cli', ->
  @timeout 2000

  it "should fail with a help message if missing 'moduleName'", (done) ->
    {cli, output} = cliRun []

    cli.on 'close', ->
      output.should.eql [
        source: 'stdout'
        message: "Missing required positional argument: 'moduleName'\n"
       ,
        source: 'stdout'
        message: 'Usage: axiom <moduleName> <serviceName> [<--arg> <value> ...]\n\n\n'
      ]
      done()

  it "should fail with a help message if missing 'serviceName'", (done) ->
    {cli, output} = cliRun ['hello']

    cli.on 'close', ->
      output.should.eql [
        source: 'stdout'
        message: "Missing required positional argument: 'serviceName'\n"
       ,
        source: 'stdout'
        message: 'Usage: axiom <moduleName> <serviceName> [<--arg> <value> ...]\n\n\n'
      ]
      done()

  it 'should start server', (done) ->
    args = ['hello', 'world']
    cwd = rel '../sample/project2'

    {cli, output} = cliRun args, cwd

    cli.on 'close', ->
      output.should.eql [
        {source: 'stdout', message: 'Hello, world!\n'}
      ]
      done()

  it "should accept a '--debug' logging flag", (done) ->
    true.should.be.false
    done()

  it "should accept an '--error' logging flag", (done) ->
    true.should.be.false
    done()

  it "should accept an '--info' logging flag", (done) ->
    true.should.be.false
    done()
