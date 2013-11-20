path = require 'path'
should = require 'should'
logger = require 'torch'
{spawn, exec} = require 'child_process'

rel = (name) -> path.join __dirname, name

command = rel '../bin/axiom'
args = ['hello', 'world']

sampleProject = rel '../sample/project2'

describe 'cli', ->
  @timeout 0

  it 'should start server', (done) ->
    cli = spawn command, args, {cwd: sampleProject}

    output = []
    ['stdout', 'stderr'].forEach (source) ->
      cli[source].setEncoding 'utf8'
      cli[source].on 'data', logger.yellow
      cli[source].on 'data', (message) -> output.push({source, message})

    cli.on 'close', ->
      console.log {output}
      output.should.eql [
        {source: 'stdout', message: 'Hello, world!\n'}
      ]
      done()

    # exec "coffee #{rel('../bin/axiom')}", {cwd: sampleProject}, (err, stdout, stderr) ->
    #   logger.cyan {err, stdout, stderr}
