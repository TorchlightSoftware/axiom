path = require 'path'

logger = require 'torch'
should = require 'should'

findProjectRoot = require '../lib/findProjectRoot'

sampleProjDir = path.join __dirname, '../sample/project1'

describe 'findProjectRoot', ->
  it 'should stop when it finds an package.json below another', (done) ->
    testDir = path.join(sampleProjDir, 'a1', 'a2')

    expected = path.join(sampleProjDir, 'a1')
    root = findProjectRoot(testDir)
    root.should.eql expected
    done()

  it 'should stop when it finds a package.json', (done) ->
    testDir = path.join(sampleProjDir, 'b1', 'b2', 'b3')

    root = findProjectRoot(testDir)
    root.should.eql sampleProjDir
    done()

  it 'should return undefined when it cannot find a package.json', (done) ->
    testDir = '/'

    root = findProjectRoot(testDir)
    should.not.exist root
    done()
