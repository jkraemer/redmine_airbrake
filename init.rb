Redmine::Plugin.register :redmine_airbrake do
  name 'Redmine Airbrake Server plugin'
  author 'Jens Kraemer'
  author_url 'https://jkraemer.net/'
  description 'Turns Redmine into an Airbrake compatible server, i.e. an API provider which can be used with the Airbrake gem.'
  url 'https://github.com/jkraemer/redmine_airbrake'
  version '1.0.0'
  hidden(true) if respond_to?(:hidden) # hide plugin in Planio

  requires_redmine :version_or_higher => '2.6.0'
end

Rails.configuration.to_prepare do
  RedmineAirbrake::Patches::IssuePatch.apply unless Issue.respond_to?(:notify?)
end

