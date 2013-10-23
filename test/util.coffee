path = require 'path'

logger = require 'torch'
should = require 'should'

util = require '../lib/util'


testDir = __dirname
projDir = path.dirname testDir
sampleDir = path.join projDir, 'sample'
sampleProjDir = path.join sampleDir, 'project'


describe 'util.findProjRoot', ->
  it 'should stop when it finds an package.json below another', (done) ->
    process.chdir path.join(sampleProjDir, 'a1', 'a2')
    expected = path.join(sampleProjDir, 'a1')
    root = util.findProjRoot()
    root.should.eql expected
    done()

  it 'should stop when it finds a package.json', (done) ->
    process.chdir path.join(sampleProjDir, 'b1', 'b2', 'b3')
    root = util.findProjRoot()
    root.should.eql sampleProjDir
    done()

  it 'should return undefined when it cannot find a package.json', (done) ->
    process.chdir '/'
    root = util.findProjRoot()
    should.not.exist root
    done()
