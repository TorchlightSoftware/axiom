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

describe 'util.projRel', ->
  it "should return the project root when relative path is '.'", (done) ->
    process.chdir path.join(sampleProjDir, 'b1', 'b2', 'b3')
    projRoot = util.findProjRoot()

    relPath = util.projRel '.'
    relPath.should.eql projRoot
    done()

  it 'should return the right relative path', (done) ->
    process.chdir path.join(sampleProjDir, 'b1', 'b2', 'b3')
    projRoot = util.findProjRoot()

    subPath = 'someplace'
    expected = path.join(projRoot, subPath)
    util.projRel(subPath).should.eql expected

    done()
