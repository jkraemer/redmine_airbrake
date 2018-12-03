Redmine Airbrake Plugin [![Build Status](https://travis-ci.org/jkraemer/redmine_airbrake.svg?branch=master)](https://travis-ci.org/jkraemer/redmine_airbrake)
==============

This plugin makes Redmine act like an [Airbrake](http://airbrake.io/)
server. Any exceptions caught and sent by Airbrake client libraries will create
or update an issue in Redmine.

This is a complete rewrite of the
[redmine_hoptoad_server](https://github.com/jkraemer/redmine_hoptoad_server)
plugin. It supports the Airbrake XML (v2) and JSON (v3) APIs. If you need to
support the ancient Hoptoad / Airbrake v1 API, use the redmine\_hoptoad\_server
plugin instead.

Supports Redmine from 2.6 onwards.

Plugin setup
------------

Just install the Plugin following the general Redmine plugin installation
instructions at http://www.redmine.org/wiki/redmine/Plugins.

Then, go to Administration -> Settings -> Incoming emails in your Redmine and
generate an API key.


Client configuration
--------------------

In order to work properly, the plugin needs some data supplied by the client.
This data is supplied as a hash with the following keys:

project
: Redmine project identifier where issues should be created

tracker
: tracker to use

api\_key
: Redmine API key as created above

category
: Issue category (optional)

assigned\_to
: Redmine login of a user the tickets should get assigned to by default (optional)

author
: Redmine login if the user to serve as issue creator

priority
: Id of a Redmine issue priority (optional)

environment
: gets prepended to the issue's subject and is stored as a custom issue field. useful to distinguish errors on a test system from those on the production system (optional)

repository\_root
:  this optional argument overrides the project wide repository root setting (see below).


Set up the Airbrake client according to the docs found at http://airbrake.io.
When it comes to configuring the client, deviate from the instructions and
supply the necessary configuration like this:


### Airbrake v3 (JSON API)

This will work with any current Airbrake client, i.e. the airbrake-ruby client
library from version 5 onwards.

Set up a filter that adds the config hash to the Airbrake notification before
it gets sent:

    Airbrake.configure do |config|
      config.project_id = 1234
      config.project_key = 'secret'
      config.host = 'https://my_redmine_host.com/'
      config.root_directory = Rails.root.to_s
    end

    Airbrake.add_filter do |notice|
      notice[:context][:redmine_config] = {
        tracker: 'Bug',
        api_key: 'my_redmine_api_key',
        project: 'project_identifier',
        # ... other redmine_airbrake configuration options as above
      }
    end

Set the `project_id` to any number, it is ignored by this plugin but validated
by the Airbrake client. The same is true for the `project_key` string.

The `root_directory` Airbrake option shortens backtrace lines by replacing your
projects installation directory with `[PROJECT_ROOT]` or (since [airbrake-ruby 2.9+](https://github.com/airbrake/airbrake-ruby/pull/311/commits/d6e3855a66a104162ba1beba3f1da559a80130bd) with `/PROJECT_ROOT/`)


Congratulations. You can now start receiving exceptions in Redmine!

#### Deprecated: Transmit config via project-key

This does not work with recent (as of January 2018) versions of the airbrake
client library. Since the filter-based method above that was intruced because
of that should work in all cases, this is left in here mainly for historical
reasons:

    Airbrake.configure do |config|
      config.project_id = 1234
      config.project_key = CGI.escape({
        tracker: 'Bug',
        api_key: 'my_redmine_api_key',
        project: 'project_identifier',
        # ... other redmine_airbrake configuration options as above
      }.to_json)
      config.host = 'https://my_redmine_host.com/'
      config.root_directory = Rails.root.to_s
    end

#### Deprecated: Airbrake v2 (XML API)

Since the Airbrake client is not designed to handle arbitrary parameters, we
trick it by setting the API-Key value to a JSON-encoded hash holding our
configuration. This hash may hold the following keys:

This applies e.g. to the Ruby airbrake gem in versions < 5.0:

    Airbrake.configure do |config|
      config.api_key = {
        :project => 'project_identifier',
        :tracker => 'Bug',
        :api_key => 'my_redmine_api_key',
        :category => 'Development',
        :assigned_to => 'admin',
        :priority => 5,
        :environment => 'staging',
        :repository_root => '/some/path'
      }.to_json
      config.host = 'my_redmine_host.com' # the hostname your Redmine runs at
      config.port = 443                   # the port your Redmine runs at
      config.secure = true                # sends data to your server via SSL (optional.)
    end

I will certainly drop support for this API at some point, please upgrade your
client.




### More Configuration (please read on!)

After you received the first exception in a Redmine project, you will notice
two new project custom fields here. Those are *Backtrace filter* and
*Repository root*.

#### Backtrace filter

If you'd like to (and we really recommend you do!) filter the backtraces that
are shown in the journal entries created by this plugin, you can set this field
to a list of expressions (one per line) to be filtered out to that field.
The filtered backtrace will only contain frames from locations not matching any
of these expressions.

I usually simply set my filter to `[GEM_ROOT]` so the filtered backtrace only
contains frames in code that's _not_ part of any Ruby gems, but if you find
other code cluttering up your backtraces, you might want to include
those source files as well.


#### Repository root

All Issues created will have a source link in their description which --
provided that you have your source repository linked to your Redmine project --
leads you directly to the file and line in your code that has caused the
exception. Your repository structure most likely won't match the structure of
your deployed code, so you can add an additional repository root.  Just use
"trunk" for a general SVN setup for instance.

You may use the `:repository_root` option in your application's airbrake.rb to
override this setting with a custom value. This is helful in case you have
multiple applications in the same repository reporting errors to the same
Redmine project.

#### Dependencies

[Nokogiri](https://github.com/sparklemotion/nokogiri) For parsing V2 XML
requests.

[airbrake-ruby](https://github.com/airbrake/airbrake-ruby) for tests.

If you need to parse requests using yaml encoded options as they were used with the [redmine_hoptoad_server](https://github.com/jkraemer/redmine_hoptoad_server) plugin, add the [Safe YAML](https://github.com/dtao/safe_yaml) gem to your Redmine's `Gemfile.local`.


License
-------

GPL v2 or any later version


Authors
-------

Jens Kraemer (https://jkraemer.net)

The original [redmine_hoptoad_server](https://github.com/yeah/redmine_hoptoad_server) plugin was created by Jan Schulz-Hofen, Planio GmbH (http://plan.io).

