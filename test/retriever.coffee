_ = require 'lodash'
{join} = require 'path'

should = require 'should'
logger = require 'torch'

findProjectRoot = require '../lib/findProjectRoot'
sampleProjDir = join __dirname, '../sample/project'

describe 'retriever', ->
  beforeEach ->
    targetDir = join(sampleProjDir, 'b1', 'b2', 'b3')
    @retriever = _.clone require '../lib/retriever'
    @retriever.projectRoot = findProjectRoot(targetDir)

  it "should have correct 'projectRoot'", (done) ->
    should.exist @retriever?.projectRoot
    @retriever.projectRoot.should.eql sampleProjDir
    done()

  it "should construct correct project-relative paths", (done) ->
    @retriever.rel().should.eql sampleProjDir
    @retriever.rel('b1').should.eql join(sampleProjDir, 'b1')
    @retriever.rel('b1', 'b2').should.eql join(sampleProjDir, 'b1', 'b2')
    done()

  it 'should load project-relative modules', (done) ->
    fake = @retriever.retrieve 'node_modules/axiom-fake'
    should.exist fake
    done()

  it 'should load project-relative Axiom extensions', (done) ->
    fake = @retriever.retrieveExtension 'fake'
    should.exist fake
    done()
