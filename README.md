antfarm(1) -- passive network mapping tool
==========================================

## SYNOPSIS

`antfarm` [ <var>global options</var> ] command|plugin [ <var>command|plugin options</var> ]

`antfarm` -h, --help

## DESCRIPTION

ANTFARM (Advanced Network Toolkit For Assessments and Remote Mapping) is a
passive network mapping application that utilizes output from existing network
examination tools to populate its OSI-modeled database. This data can then be
used to form a 'picture' of the network being analyzed.

ANTFARM can also be described as a data fusion tool that does not directly
interact with the network. The analyst can use a variety of passive or active
data gathering techniques, the outputs of which are loaded into ANTFARM and
incorporated into the network map. Data gathering can be limited to completely
passive techniques when minimizing the risk of disrupting the operational
network is a concern.

## DISCLAIMER

While the ANTFARM tool itself is completely passive (it does not have any
built-in means of gathering data directly from devices or networks), network
admin tools that users of ANTFARM may choose to gather data with may or may not
be passive. The authors of ANTFARM hold no responsibility in how users decide to
gather data they wish to feed into ANTFARM.

## FILES

Unless it already exists, a '.antfarm' directory is created in the current
user's home directory. This directory will contain a default configuration file,
the SQLite3 database used by ANTFARM (if the user specifies for SQLite3 to be
used, which is also the default), and log files generated when using ANTFARM.
Custom plugins created by users will be made available to the ANTFARM
application when they are placed in the '.antfarm/plugins' directory.

## OPTIONS

ANTFARM's default method of operation is to parse input data or generate output
data using a specified plugin. The plugin to use is specified on the command
line as a sub-command, and each plugin developed specifies it's own required
arguments. Global ANTFARM options include:

  * `-e`, `--env` <var>env</var>:  
    The ANTFARM environment to use when executing the given sub-command. The
    default environment is 'antfarm'. Setting the environment variable affects
    things like database used, log file used and configuration settings used.

  * `-l`, `--log-level` <var>level</var>:  
    The log level used when executing the given sub-command. Optional levels
    include debug, info, warn, error and fatal. The default log level used is
    'warn'.

  * `-p`, `--prefix` <var>prefix</var>:  
    The default subnet prefix used when IP interfaces are created using IP
    address data that does not include subnet mask information. The default
    prefix used is 30.

  * `-v`, `--version`:  
    Display the current version of ANTFARM.

  * `-h`, `--help`:  
    Display useful help information for ANTFARM.

To avoid having to provide these global options at the command line every time
ANTFARM is run, users can choose to set the default values for these options in
the configuration file located at '~/.antfarm/config.yml'. An example YAML
config file is below.

    ----
    # set the default global options
    environment: foo
    log_level:   debug
    prefix:      30

    foo: # set the database adapter for environment 'foo'
      adapter: sqlite3

    bar: # set the database adapter for environment 'bar'
      adapter: postgres

## COMMANDS

  * `antfarm` or `antfarm -h` or `antfarm help`:  
    Display the default help message for ANTFARM

  * `antfarm list`:  
    List all the plugins currently available in ANTFARM

  * `antfarm help <var>plugin</var>`:  
    Show information specific to an available ANTFARM plugin

  * `antfarm console` or `antfarm -e <var>env</var> console`:  
    Drop into a console with access to all the ANTFARM data models

  * `antfarm init` or `antfarm -e <var>env</var> init`:  
    (Re)Initialize the ANTFARM database (warning -- destructive!)

  * `antfarm pcap -f path/to/pcap/file.pcap`:  
    Execute the ANTFARM pcap plugin

  * `antfarm -e <var>env</var> pcap -f path/to/pcap/file.pcap`:  
    Execute the ANTFARM pcap plugin using a specified environment

  * `antfarm -e <var>env</var> -l debug pcap -f path/to/pcap/file.pcap`:  
    Execute the ANTFARM pcap plugin using a specified environment and log level

## PLUGINS

ANTFARM boasts a plugin architecture that makes it easy for users to quickly
develop their own plugins to support new input, output, and analysis
capabilities. Once developed and tested, plugins can either be pulled into the
main ANTFARM Gem or can be packaged up as its own Rubygem. The main ANTFARM
Gem includes some Rubygem plugin code that registers Gem install/uninstall hooks
to look for new ANTFARM plugins being installed as Gems. When a Gem whose name
begins with 'antfarm-' is installed, the Gem install hook registered by the main
ANTFARM Gem copies relevant files from the newly installed Gem into the user's
'~/.antfarm/plugins' directory. Similarly, when a Gem whose name begins with
'antfarm-' is uninstalled, the Gem uninstall hook registered by the main ANTFARM
Gem deletes the relevant directory from the user's '~/.antfarm/plugins'
directory.

To develop a plugin, one should clone the ANTFARM Git repository and bootstrap
the development environment by running 'bundle install'. From there, the local
version of ANTFARM can be run via 'bundle exec ruby bin/antfarm ...'. Plugins
live in the 'lib/antfarm/plugins' directory and should be in a subdirectory that
matches the name of the plugin. Within that named subdirectory, the file ANTFARM
looks for is 'plugin.rb'. This file is expected to implement a few required
methods that the ANTFARM plugin architecture requires. A minimalist example is
shown below with some informational comments included.

    module Antfarm
      module Foo
        # This is a required method, and is called after the plugin is
        # registered in the ANTFARM application (see last line of code).
        def self.registered(plugin)
          # This is the name of the plugin as it should be used on the command
          # line. It is assumed that this name matches the plugin directory
          # name.
          plugin.name = 'foo'
          # This is used when displaying the list of available plugins via the
          # main ANTFARM command.
          plugin.info = {
            :desc   => 'The dreaded Foo plugin...',
            :author => 'John Doe'
          }
          # These are the options that are required for the plugin. They are
          # parsed by the Trollop Gem and provided to the 'run' command below.
          plugin.options = [{
            :name     => 'file', # '--file' on the command line
            :desc     => 'Config file to parse (can also be a directory)',
            :type     => String,
            :required => true
          },
          {
            :name => 'print_output', # '--print-output' on the command line
            :desc => 'Print the output to screen when parsing'
          }]
        end

        def run(opts)
          # This is a built-in helper method in the plugin architecture that
          # will confirm the options provided meet all the requirements as
          # defined above, over and beyond what Trollop doesn't check. It raises
          # exceptions if any errors are encountered.
          check_options(opts)

          # Examples of how to pull data from provided options.
          file_name    = opts[:file]
          print_output = opts[:print_output]

          # This is another built-in helper method in the plugin architecture
          # that provides an easy way of reading in a file or a directory of
          # files. It also makes it easier to write tests for plugins that can
          # provide data via a StringIO object rather than an actual file.
          read_data(file_name) do |path,lines|
            lines.each do |line|
              # Do something with each line of data...
            end
          end
        end
      end
    end

    # This is required -- registeres the above plugin with the ANTFARM plugin
    # architecture when this file is loaded during initialization.
    Antfarm.register(Antfarm::Foo)

Ideally, tests will be developed along with each plugin. These can be placed in
the 'test' directory and as long as the name of the test file ends with
'_test.rb' it will be automatically included when 'rake test' is run.

## HOMEPAGE

See https://github.com/ccss-sandia/antfarm for more details.

## COPYRIGHT

Copyright (2008-2014) Sandia Corporation. Under the terms of Contract
DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains certain
rights in this software.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, distribute with modifications,
sublicense, and/or sell copies of the Software, and to permit persons to whom
the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or other
dealings in this Software without prior written authorization.


[SYNOPSIS]: #SYNOPSIS "SYNOPSIS"
[DESCRIPTION]: #DESCRIPTION "DESCRIPTION"
[DISCLAIMER]: #DISCLAIMER "DISCLAIMER"
[FILES]: #FILES "FILES"
[OPTIONS]: #OPTIONS "OPTIONS"
[COMMANDS]: #COMMANDS "COMMANDS"
[PLUGINS]: #PLUGINS "PLUGINS"
[HOMEPAGE]: #HOMEPAGE "HOMEPAGE"
[COPYRIGHT]: #COPYRIGHT "COPYRIGHT"


[antfarm(1)]: antfarm.1.html
