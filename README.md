Redmine Airbrake Plugin [![Build Status](https://travis-ci.org/jkraemer/redmine_airbrake.svg?branch=master)](https://travis-ci.org/jkraemer/redmine_airbrake) \_
==============

This plugin makes Redmine act like an [Airbrake](http://airbrake.io/) (formerly
known as Hoptoad) server. All exceptions caught and sent by Airbrake client
libraries will create or update an issue in Redmine.

This plugin is a complete rewrite of the [redmine_hoptoad_server](https://github.com/jkraemer/redmine_hoptoad_server) plugin. It supports the Airbrake XML (v2) and JSON (v3) APIs. If you need to support the ancient Hoptoad / Airbrake v1 API, use the `redmine_hoptoad_server` plugin instead.

Plugin setup
------------

Just install the Plugin following the general Redmine plugin installation
instructions at http://www.redmine.org/wiki/redmine/Plugins.

Then, go to Administration -> Settings -> Incoming emails in your Redmine and
generate an API key.


Client configuration
--------------------


In order to work properly, the plugin needs some data supplied by the client.
Since the Airbrake client is not designed to handle arbitrary parameters, we
trick it by setting the API-Key value to a JSON-encoded hash holding our
configuration. This hash may hold the following keys:

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

### Airbrake v2 (XML API)

This applies e.g. to the Ruby airbrake gem, version < 5.0:

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


### Airbrake v3 (JSON API)_

This applies if you're using the airbrake gem version >= 5.0.

    Airbrake.configure do |config|
      config.project_id = 'redmine_project_identifier',
      config.project_key = {
        :tracker => 'Bug',
        :api_key => 'my_redmine_api_key',
        # ... other redmine_airbrake configuration options as above
      }.to_json
      config.host = 'https://my_redmine_host.com/'
      config.root_directory = Rails.root.to_s
    end

As you can see the major difference is that there is now a `project_id` and
`projec_key` where we just had an `api_key` before. Also setting the target
host (that's your Redmine running this plugin) has become much simpler - just
put a complete URL into the `host` field and you're done. The `root_directory`
Airbrake option shortens backtrace lines by replacing your projects
installation directory with `[PROJECT_ROOT]`


Congratulations. You can now start receiving your Exceptions in Redmine!


### More Configuration (please read on!)

After you received your first exception in Redmine, you will notice two new
custom fields in the project(s) you've received the exceptions for. Those are
*Backtrace filter* and *Repository root*.

#### Backtrace filter

If you'd like to (and we really recommend you do!) filter the backtraces that
Notifier reports, you can add comma separated strings to that field. Every line
in a backtrace will be scanned against those strings and matching lines *will
be removed*. I usually set my filter to `[GEM_ROOT]`, but if you're using
plugins which tend to clutter up your backtraces, you might want to include
those as well. Like this for example: `[GEM_ROOT],[RAILS_ROOT]/vendor/plugins/newrelic_rpm`.

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

