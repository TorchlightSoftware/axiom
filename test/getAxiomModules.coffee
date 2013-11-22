should = require 'should'

getAxiomModules = require '../lib/getAxiomModules'


tests = [
  description: "should get only 'axiom'-prefixed extension modules"
  pkg:
    dependencies:
      'axiom-hello': '*'
      'axiom-world': '*'
      'not-axiom': '*'
      'also-not-axiom': '*'
  blacklist: null
  expected: ['hello', 'world']
 ,
  description: "should get extension modules from 'devDependencies'"
  pkg:
    dependencies:
      'axiom-hello': '*'
      'not-axiom': '*' # should not appear
    devDependencies:
      'axiom-world': '*'
      'also-not-axiom': '*' # should not appear
  blacklist: null
  expected: ['hello', 'world']
 ,
  description: "should not get duplicates from 'dependencies', 'devDependencies'"
  pkg:
    dependencies:
      'axiom-a': '*'
      'axiom-b': '*' # duplicated
    devDependencies:
      'axiom-b': '*' # duplicated
      'axiom-c': '*'
  blacklist: null
  expected: ['a', 'b', 'c']
]

describe 'getAxiomModules', ->
  for test in tests
    do (test) ->

      # Given a parsed 'package.json' and a blacklist
      {description, pkg, blacklist, expected} = test

      it description, (done) ->

        # When we call the function
        result = getAxiomModules pkg, blacklist

        # We get the expected result
        result.should.eql expected

        done()
