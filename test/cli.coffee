path = require 'path'
should = require 'should'
logger = require 'torch'
{spawn, exec} = require 'child_process'

rel = (name) -> path.join __dirname, name

command = rel '../bin/axiom'
args = ['hello', 'world']
#command = 'ls'
#args = []

sampleProject = rel '../sample/project2'

describe 'axiom-cli', ->

  it 'should start server', (done) ->
    logger.blue sampleProject
    #cli = spawn command, args, {cwd: sampleProject}

    #output = []
    #['stdout', 'stderr'].forEach (source) ->
      #cli[source].setEncoding 'utf8'
      #cli[source].on 'data', logger.yellow
      #cli[source].on 'data', (message) -> output.push({source, message})

    #cli.on 'close', ->
      #output.should.eql [
        #{source: 'stdout', message: 'Hello, world!'}
      #]
      #done()

    exec "coffee #{rel('../bin/axiom')}", {cwd: sampleProject}, (err, stdout, stderr) ->
      logger.cyan {err, stdout, stderr}
