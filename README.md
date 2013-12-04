# Axiom

Axiom is a system for formalizing productive workflows, and defining the runtime of your application in a decoupled, extensible way.

At its core, Axiom is:

* A protocol for sub-system communication
* A standard for sub-system definition

Sub-systems are stored as NPM modules, and may include:

* A configuration
* Processes for:
  * Install/Uninstall
  * Build
  * Test
  * Runtime
  * Feature Scaffolding

These processes can extend existing life-cycles or define their own.

# Alternatives

* Yeoman - Used for formalizing workflows, workflows are not extensible, there is no standard for organizing/extending the application runtime.
* FireShell - Ditto.
* Anvil.js - Very similar design goals to Axiom, and in fact we use the same underlying message bus (Postal.js).  Whereas Anvil.js decided to bake in the lifecycles, we wanted these to be extensible and therefore we have a more lightweight core than Anvil ships with.  We also wanted to extend the decoupled approach of tasks to building out the application runtime.

# Installation

```bash
npm install -g axiom
```

# Usage

```bash
axiom core create
# Creates a new app (creates the directory as well).
# This is the only command designed to be run outside the project directory.
# If you already have a directory that you would like to start with, running any
# install (or install with no args) should check all required baseline artifacts
# and install them if they don't exist.

axiom [module] install
# Automatically does the following:
#   1) npm install axiom-[module] --save
#   2) require axiom-[module]
#   3) run 'install' if it exists

axiom [module] uninstall
# Automatically does the following:
#   1) require axiom-[module]
#   2) run 'uninstall' if it exists
#   3) npm uninstall axiom-[module] --save

axiom [module] [task]
axiom client build
# If you have installed an axiom named "client" and it has a task called "build", this
# will run that task.

axiom client test
axiom server test
# Again, these assume axioms/tasks that exist with those names.
```

# Building Axioms

Simply publish on npm a module with the name format 'axiom-yourname'.  This will then be discovered by `axiom install`, and once installed will be automatically referanceable from the Axiom CLI.

Your module should export an object containing the keys:

* config - A javascript object describing how to wire up the services in this module.
* services - Functions of a standard signature which implement your intended functionality.

Services should contain:

* install - A function to install the axiom.  Include any generation code here.
* uninstall - A function to uninstall the axiom.  Remove all the generated code and directories/files that would have resulted from the installation.
* [anything_else] - A function to generate some files, deploy something, start a server, or run a task.

Services are in the format of:

```coffee-script
(args, done) ->
  {foo, bar} = args
  done null, {message: 'hello'}
```

These conform to the specification for Law services, so if you want some middleware to help you out (argument validations, access controls, filters for common functionality), check out the Law documentation:

https://github.com/torchlightsoftware/law

Here's an example module definition using Law:

```coffee-script
law = require 'law'
serviceDefs = law.load './services'

module.exports =
  config:
    test:
      base: 'task'
      stages: ['prepare', 'test', 'cleanup']

  services: law.create {
      services: serviceDefs
      policy: require './policy'
    }

```

## DISCLAIMER

Modules in the Axiom ecosystem are the property of their respective authors.  We make no guarantee for the quality, usefulness, or intent of any module.

## LICENSE

(MIT License)

Copyright (c) 2013 Torchlight Software <info@torchlightsoftware.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
