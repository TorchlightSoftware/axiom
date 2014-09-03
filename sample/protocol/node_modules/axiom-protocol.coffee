standardSignals =
  start: ['load', 'link', 'run']
  stop: ['halt', 'unlink', 'unload']

task =
  type: 'task'
  signals: standardSignals

agent =
  type: 'agent'
  signals: standardSignals

module.exports =
  protocol:

    client:
      build: task
      test: task
      run: agent
      deploy: task

    server:
      run: agent
      test: task
