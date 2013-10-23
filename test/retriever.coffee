path = require 'path'

should = require 'should'

{findProjRoot} = require '../lib/util'


testDir = __dirname
projDir = path.dirname testDir
sampleDir = path.join projDir, 'sample'
sampleProjDir = path.join sampleDir, 'project'


describe 'retriever', ->
  beforeEach ->
    process.chdir path.join(sampleProjDir, 'b1', 'b2', 'b3')
    @retriever = require '../lib/retriever'
    @retriever.projRoot = findProjRoot()

  it "should have correct 'projRoot'", (done) ->
    should.exist @retriever.projRoot
    @retriever.projRoot.should.eql sampleProjDir
    done()

  it "should construct correct project-relative paths", (done) ->
    @retriever.rel().should.eql sampleProjDir
    @retriever.rel('b1').should.eql path.join(sampleProjDir, 'b1')
    @retriever.rel('b1', 'b2').should.eql path.join(sampleProjDir, 'b1', 'b2')
    done()

  it 'should load project-relative modules', (done) ->
    fake = @retriever.retrieve 'node_modules/axiom-fake'
    should.exist fake
    done()

  it 'should load project-relative Axiom extensions', (done) ->
    fake = @retriever.retrieveExtension 'fake'
    should.exist fake
    done()
