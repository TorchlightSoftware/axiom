# Axiom

Axiom is the anti-framework.  If you prefer libraries over frameworks, but are looking for a place to put your integration, setup, and configuration options, this is for you.

Axiom can be used to create productive workflows, while retaining the flexibility and maintainability that comes from utilizing decoupled components.

At its core, Axiom is:

* A message bus for sub-system communication
* A standard for sub-system definition

Sub-systems are called axioms, and may include:

* A configuration
* Processes for:
  * Install/Uninstall
  * Build
  * Test
  * Runtime
  * Feature Scaffolding

# Alternatives

Yeoman fulfills a similar role in that it provides a place to store the 'recipes' that are commonly used by your organization.  So why not just use a build tool?

Have you ever found yourself wanting to initialize parts of your application within a script?  Maybe you want to have access to the models so you can run a batch script.  Maybe you want to initialize a subsegment of the application for testing.

Have you ever installed a new module in your application, and found yourself handling the integration at multiple points?

Axiom was designed to solve these problems.  By defining standard roles that components fulfill, and a standard interface by which they communicate, we can build upon a foundation that makes simple things easy, but won't back us into a corner when things get complex.

# Usage

```bash
axiom create [project]
# Creates a new app (creates the directory as well).
# This is the only command designed to be run outside the project directory.
# If you already have a directory that you would like to start with, running any
# install (or install with no args) should check all required baseline artifacts
# and install them if they don't exist.

axiom run
# Runs your app.

axiom install [axiom]
# Automatically does the following:
#   1) add to package.json
#   2) npm install [axiom]
#   3) run 'install'

axiom uninstall [name]
# Automatically does the following:
#   1) require [axiom-name], run 'uninstall' if it exists
#   2) remove from package.json
#   3) npm uninstall [axiom-name]

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

* install - A function to install the axiom.  Include any generation code here.
* uninstall - A function to uninstall the axiom.  Remove all the generated code and directories/files that would have resulted from the installation.
* [anything_else] - A function to generate some files, deploy something, start a server, or run a task.

# Axiom Runtime

*UNSTABLE - IN DISCUSSION*

Axiom maintains event buses which act as the main communication between subsystems.  When a task is run it will be bound to an event bus through which it can listen to relevant events and emit its own.  The event bus will contain the following keys:

* on/off - listen to messages
* emit - send a message
* config - the config for the corresponding axiom

The axiom must specify any namespaces it wishes to listen to.  Aliases are possible as well - one or more source namespaces can be merged into a target namespace which the axiom will listen to.  When 'emit' is called the message will automatically be aliased under the axiom name.

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
