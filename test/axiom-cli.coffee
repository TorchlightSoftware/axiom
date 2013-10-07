path = require 'path'

should = require 'should'
mockery = require 'mockery'
logger = require 'torch'
sample = require '../sample/sample'

{spawn} = require 'child_process'

binDir = path.join __dirname, '..', 'bin'
command = path.join binDir, 'axiom'


tests = [
  {
    description: 'should fail when no module is specified'
    args: []
    expected:
      code: 1
      stderr: [
        'Options:\n  --moduleName, --module, -m    [required]\n  --serviceName, --service, -s  [required]\n  --data                        [default: {}]\n\n'
        'Missing required arguments: moduleName, serviceName\n'
      ]
  }
  # # This will be a valid test once in the actual execution environment.
  # # We can't use mockery to intercept the 'require' call because we are
  # # spawning a subprocess.
  # # Thus, this will require a real integration test, e.g. using 'npm link'.
  # {
  #   description: 'should work when module, service is specified'
  #   args: [
  #     '-m=sample'
  #     '-s=echo'
  #     "--data.greeting='hello, world'"
  #   ]
  #   expected:
  #     code: 1
  #     stderr: [
  #       "\u001b[31m[failure]\u001b[39m { err: [Error: Request timed out on channel \'sample.echo\'] }\n"
  #     ]
  # }
]

describe 'axiom-cli', ->
  @timeout 0

  beforeEach (done) ->
    @spawn = (command, args, options) ->
      @proc = spawn command, args, options
      @proc.stderr.setEncoding 'utf8'
      @proc.stdout.setEncoding 'utf8'
      return @proc

    @stderr = (cb) ->
      @proc.stderr.on 'data', cb

    @stdout = (cb) ->
      @proc.stdout.on 'data', cb

    @close = (cb) ->
      @proc.on 'close', cb

    mockery.enable
      warnOnReplace: false,
      warnOnUnregistered: false
    mockery.registerMock 'axiom-sample', sample

    done()


  afterEach ->
    mockery.disable()

  for t in tests
    do (t) ->
      {description, args, expected} = t
      stderr = expected.stderr or []
      stdout = expected.stdout or []
      returnCode = expected.code or 0
      args or= []

      it description, (done) ->
        @proc = @spawn command, args

        collected =
          stderr: []
          stdout: []

        @stderr (data) ->
          # logger 'stdout', {data}
          collected.stderr.push data

        @stdout (data) ->
          # logger 'stdout', {data}
          collected.stdout.push data

        @close (code) ->
          # logger close', {code}
          code.should.eql returnCode

          collected.stderr.should.eql stderr
          collected.stdout.should.eql stdout

          done()
