Genapp (c) 2012 CloudBees
http://www.cloudbees.com
Licenced under the AGPL. See the LICENCE file.

# Overview
genapp is used to manage the lifecycle of user applications on the CloudBees platform.

Each CloudBees server is capable of running multiple user applications. 
These applications are installed and configured (i.e. deployed) by invoking a genapp agent. 
Genapp is also used to uninstall (i.e. undeploy) applications.

genapp handles:

* Application port allocation
* Application deployment by way of plugins
* Application undeployment

genapp does not handle:

* Application packaging
* Application package deployment
* Specific application setup (these are handled by plugins)
* Application start and stop
* Application monitoring

Read the AMAZING documentation: http://genapp-docs.cloudbees.com/







**NOTE**: The documentation below is deprecated and may be out of date


    $ clone git@github.com:cloudbees/genapp.git

and open genapp/doc/_build/html/index.html in your browser.

The documentation that follows will be retained for a period of time for
reference until the other documentation is finalized.

---

TODO:

- Note group writable rule for plugins

- Hint for bash dev: use "set -x" to print statements -- BUT then REMOVE

- Separation of setup and functions (page on code reuse)

- Use of other plugins (use git subproject?)

- Note the convention of building up command line strings and calling them
  with `bash -c "$cmd"`

- Devote a whole page to the setup workflow. This should have some graphics
  that show the flow from the source dirs (`pkg_dir` and various `plugin_dir`)
  to the target dir (`app_dir`)

- Moving away from using local variables to using underscore convention. local
  variables are horrifically dangerous because they eat function return values,
  hiding errors. Underscores have the advantage of making it clear which
  variables are local and which are not.

  The point is made here:

  http://tldp.org/LDP/abs/html/localvar.html

  as the problem of "declaring and setting a local variable in a single
  command."

  We could get away with delcaring and setting in separate steps whenever
  functions are used to set values, but that's a recipe for bugs. The leading
  underscores also has other benefits, as mentioned above.

---

genapp is a light weight framework for deploying and managing applications.

# Production Requirements

In production, genapp must be run as root.

Required software:

- [Erlang][]

# Development Requirements

genapp may be run in development mode as a non-privileged user.

Required software:

- [Erlang][]

# Quick Start

Verify that you have satisfied *Development Requirements* above.

You'll also need Python version 2.x installed to test the application in
*Create a sample project* below.

## Get genapp source

Clone a genapp repository to a local directory -- this local directory is
referred to as `$genapp_home` below.

## Build genapp

Change to `$genapp_home` and run `make`:

    $ cd $genapp_home
    $ make

This process will download required libraries from github and compile the code.

## Configure Local Settings

genapp uses `priv/dev.config` by default when running locally. Copy the
configuration template:

    $ cp priv/dev.config.in priv/dev.config

Modify `priv/dev.config` as follows:

- Set `devmode` to `true`
- Set `apps_home` to an empty local directory that will contain applications
  installed by genapp (e.g. `~/genapp-dev/apps` where "~" is your home
  directory -- you must specify your home directory explicitly as genapp will
  not recognize "~")
- Set `plugins_home` to an empty directory that will contain your plugin
  definitions

Here's a sample `priv/dev.config` file (comments removed):

    [{genapp,
      [
       {devmode, true},
       {apps_home, "/home/garrett/genapp-dev/apps"},
       {plugins_home, "/home/garrett/genapp-dev/plugins"}
    ]}].

## Setup a Sample Plugin

genapp plugins are single bash script files that are [sourced][] by genapp and
that contain a `setup` function.

Copy the "simple_http" example plugin to the directory specified in the genapp
`plugins_conf_home` directory:

    $ cp -rf examples/simple_http $plugins_home

where `$plugins_home` is the plugins conf home directory you created above.

Note that the dir is named "simple_http" -- this is how genapp identifies the
plugin.

## Create a Sample Project

Create an empty directory that will serve as your application *package
directory*. For example:

    $ cd ~
    $ mkdir sample_app

Next, create the `.genapp` subdirectory inside the package directory. This will
contain genapp related files (note the leading period in the directory name):

    $ cd sample_app
    $ mkdir .genapp

Create a file named `metadata.json` inside the `.genapp` directory. It should
look like this:
    {
        "app":{
            "plugins":["simple_http"]
        }
    }

In the root of your package directory (e.g. `sample_app`), create `index.html`:

    <html>
      <p>This is my sample app!</p>
      <p>It was deployed by genapp using
        <a href=".genapp/metadata.json">metadata.json</a>.</p>
    </html>

When you're done, you should have an application package structure that looks
like this:

    sample_app/
	sample_app/.genapp/
	sample_app/.genapp/metadata.json
	sample_app/index.html

## Start genapp

From `$genapp_home` run `make shell`:

    $ cd $genapp_home
    $ make shell

This will start an interactive shell that you can use to test and debug genapp
plugins.

If you see any errors, check the "Reason" section for details. Refer to *Common
Errors* below for help.

## Deploy the Sample

In the genapp shell, run this command (note that the command ends with a period
-- this is an Erlang convention):

    1> genapp:deploy("/path/to/sample_app").

Replace `/path/to/sample_app` with the full path to the application package
directory created above.

If the applicaiton was deployed successfully, you will see `plugin_setup_ok`,
otherwise you'll see errors. Refer to *Common Errors* below for help.

If deployed successfully, genapp installed the application in a subdirectory of
`apps_home`. The subdirectory is a randomly generated eight character
name. This name is also known as the *application ID*. The application ID will
be displayed in the plugin setup info report, which looks something like this:

    {plugin_setup_ok,{<<"simple_http">>,"c73e35b4",[]}}

Use the `find` command to list the installed files:

    $ cd $app_dir
    $ find | sort

`$app_dir` is the full path to the application subdirectory in `apps_home`.

The directory structure of the installed application should look like this:

    ./.genapp
    ./.genapp/control
    ./.genapp/control/start
    ./.genapp/log
    ./.genapp/metadata.json
    ./.genapp/ports
    ./.genapp/ports/8652
    ./.genapp/setup_status
    ./.genapp/setup_status/ok
    ./.genapp/setup_status/plugin_simple_http_0
    ./index.html

## Run the Application

genapp applications are started using the file `.genapp/control/start`. From
the application directory, run:

    $ .genapp/control/start

If Python 2.x is installed on your system, you should see this output:

    Serving HTTP on 0.0.0.0 port PORT ...

`PORT` is the port that was assigned by genapp to the application.

Test the web application by visiting http://localhost:PORT in your browser.

You should see the `index.html` web page you created earlier.

## Undeploy the Application

genapp undeploys an application by deleting the application directory. You can
use the genapp shell to undeploy this way:

    genapp:undeploy("APP_ID").

Replace `APP_ID` with the eight character application ID (used application
directory name).

## Common Errors

### `missing_required_dir`

One of the directories specified in the genapp configuration does not exist.

Create the missing directories and restart genapp.

### `metadata_read`

An error occurred reading the project metadata. The error will have additional
details.

`enoent` indicates that metadata file doesn't exist. Verify that the package
directory used in the deploy operation contains `.genapp/metadata.json`.

### `{plugin_not_installed,<<"xxx">>}`

genapp could not find the plugin named "xxx".

Verify that the `plugins_home` directory as specified in
`$genapp_home/priv/dev.config` contains the expected plugin. Note that a plugin
is a bash script in the plugins conf home directory that has the same name as
the plugin.

Plugins may be copied to the conf home or symlinked as needed.

# Plugin Development

genapp uses plugins to setup an application. Each plugin listed in the
"apps.plugins" metadata is given an opportunity to perform setup operations.

Each plugin is a bash script that must define a `setup` function.

Plugin configuration files are located in `plugins_conf_home` (as defined in
the genapp configuration file -- e.g. see `priv/dev.config` in *QuickStart*
above) and must match the name value given in the project metadata.

Plugins run by the application user in production. In development mode, they
run as the USER environment variable accessible to the genapp process (defaults
to the current user).

## Plugin Environment Variables

When the plugin configuration file is sourced, it has access to a number of
environment variables it can use to perform setup:

**`plugin_conf`** the full file name of the plugin configuration file

**`pkg_dir`** the application package directory

**`app_id`** the application ID (randomly assigned eight character string)

**`app_dir`** the application directory (located in apps_home)

**`app_user`** the user associated with the application

**`genapp_dir` ** the genapp directory associated with $app_dir, which contains
  all genapp related files

**`control_dir`** the genapp control directory for the application (contains
the start script)

**`log_dir`** the genapp log directory for the application

**`app_port`** the port assigned to the application

In addition to these environment variables, plugin specific values defined in
the project metadata are provided. Variables are named using this convention:

    "plugin_" + PLUGIN_NAME + "_" + VALUE_NAME

For example, the "message" variable for the "hello" plugin can be accessed by a
plugin using "$plugin_hello_message".

Plugin metadata is specified as an JSON associative array named using

    "plugin." + PLUGIN_NAME

The "message" value above would be defined in metadata.json as follows:

    {
        "plugin.hello": {
            "message": "Hello World!"
        }
    }

## Control Files

If an application was deployed successfully, it should be runnable from its
application directory using this control file:

    .genapp/control/start

The plugins listed in the project metadata must coordinate the creation of this
control file as well as any required installation and configuration.

All control files must be executable.

The start control file should  block -- i.e. it should run in the background.

Typically, a single plugin assumes responsibility for creating the `start`
control file. Ancillary plugins may then extend or otherwise modify the core
application configuration.

## Installing Files

Plugins may install project files (e.g. files located in "$meta_home") by
copying them to the application directory (accessible as "$app_dir").

An application may alternatively specify a location for files in metadata --
plugins can download, copy, etc. those files as needed.

There is no standard for file installation -- each project author must comply
with the requirements of the plugins it specifies in metadata.

## Application File Permissions

Plugins run as the application user and are restricted to write access within
the application directory.

During setup, plugins are free to modify the contents of the application
directory as needed.

Once the setup is finalized genapp recursively sets file ownership within the
application directory as follows:

- File and directory owner is "root"
- File and directory group is the application user's primary group

As a result, only files marked by plugins as "group writable" can be modified
by the application.

If for example an application writes to a "log" subdirectory, a plugin must
create that directory and make it group writable:

    mkdir -m 770 log

## Plugin Development Workflow

### Application Type

A plugin typically specializes in installing and configuring a particular type
of application.

Some application types include:

- Precompiled executable binaries
- Language specific projects
- Framework specific projects

Start by establishing some familiarity with the application type and how it
should be installed and configured. If you're unfamiliar with the target
application type, follow a simple tutorial to get a feel for its runtime
requirements.

### "Project" to "Applicaiton" Mapping

If a plugin is installing a precompiled, pre-packaged application, its job is
simple -- it needs to copy the required runtime files and generate a simple
shell script wrapper for the application's executable.

In many cases however, a plugin needs to tranform project artifacts to
appropriate runtime artifacts. These are the types of operations a plugin might
perform:

- Compile source code to executables or bytecode
- Generate start scripts that contain appropriate configuration
- Create application directory skeletons and copy project files to the
  appropriate runtime locations

### Plugin Configuration
[WARNING:  this section is out of date - (says spike 9/18/2012)]
Start your plugin development with a single configuration file, either located
in `plugins_conf_home` (see above) or symlinked to that directory.

The file or link in `plugins_conf_home` can be used in the "app.plugins"
metadata list.

In the plugin file, create a `setup` function like this:

    setup() {
        echo 'while true; do echo "TODO: run my app"; sleep 1; done' > \
            "$control_dir/start"
        chmod 550 "$control_dir/start"
    }

### Test Application

Create a test application that contains a `.genapp` subdirectory, which in turn
contains a `metadata.json` file that looks like this:

    {
        "app.plugins": ["my_plugin"]
    }

Replace `my_plugin` with the name of your plugin (i.e. the name of the file or
symlink in `plugin_conf_home`).

Deploy the test application in the genapp shell:

    genapp:deploy("/path/to/my_app").

Replace `/path/to/my_app` with the fill path to your test app directory
(i.e. the directory containing `.genapp/metadata.json`).

Run the application by executing its `start` script, which was created by the
plugin. You should see a repeating list of:

    TODO: run my app
    TODO: run my app
    ...

Type CTRL-C to stop the script.

### Iterate

From this point, start to assemble a real application by modifying the plugin
setup function and the test application in sync.

Each iteration will result in a new deployed application. You can freely delete
old application directories when you no longer need them.

## Hints

### Separate `setup` into multiple functions

If a `setup` function becomes hard to read, you can create separate functions
that may improve your code. Here's an example:

    install_files() {
        cp -a $meta_home/app/* $app_dir/
    }

    create_control_files() {
        install -m 550 $plugin_home/templates/start $control_dir/start
    }

    setup() {
        install_files
        create_control_files
    }

### Freely use plugin supporting files

Non-trivial plugins will not be implemented as a single file. The plugin
configuration file may reference plugin-specific files from a well known (or
configured) location. The plugin should be installed or configured so that it
can access its supporting files.

Here's a simple example of a `setup` that references a "start template",
located in "plugin home":

    plugin_home=/usr/lib/my-plugin

    setup() {
        install -m 550 $plugin_home/start_template $control_dir/start
    }

In "development mode" you might located "plugin_home" in your home directory,
source code directory, etc.

### Sample bash Commands

**Create a directory with group write permissions**

    mkdir -m 770 delme

**Copy a file and set it as executable**

    install -m 550 $src_file $dest_file

**Create a multiline script**

    cat > $start_script << EOF
    #!/bin/sh
    exec python2 -m SimpleHTTPServer $app_port
    EOF

### Debugging

Errors will occur in three places:

- Durring deployment
- While starting an application
- While running an application

genapp will print errors in the shell during the `deploy` command. You can also
look in `.genapp/setup_status/` for details on a failed installation.

You'll see errors directly in the system console when calling
`.genapp/control/start`.

Application runtime errors will typically be displayed as standard output or
error messages while the application is running.

In most cases you should see a clear error message and a script line number
that will help you identify the problem.

### Miscellaneous

- Always run applications in the foreground (i.e. not as daemons/background
  processes)

- Alays use [exec][] to run the application process from the `start` script

- Remember to make files and directories group writable whenever the
  application needs to modify them

[runit]: http://smarden.org/runit/
[Erlang]: http://www.erlang.org
[sources]: http://ss64.com/bash/period.html
[exec]: http://ss64.com/bash/exec.html
