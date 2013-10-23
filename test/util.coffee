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


describe 'util.makeLoader', ->
  beforeEach ->
    process.chdir path.join(sampleProjDir, 'b1', 'b2', 'b3')
    @loader = util.makeLoader()
    should.exist @loader

  it "should have correct 'projRoot'", (done) ->
    should.exist @loader.projRoot
    @loader.projRoot.should.eql sampleProjDir
    done()

  it "should construct correct project-relative paths", (done) ->
    @loader.rel().should.eql sampleProjDir
    @loader.rel('b1').should.eql path.join(sampleProjDir, 'b1')
    @loader.rel('b1', 'b2').should.eql path.join(sampleProjDir, 'b1', 'b2')
    done()

  it 'should load project-relative modules', (done) ->
    fake = @loader.load 'node_modules/axiom-fake'
    should.exist fake
    done()

  it 'should load project-relative Axiom extensions', (done) ->
    fake = @loader.loadExtension 'fake'
    should.exist fake
    done()
