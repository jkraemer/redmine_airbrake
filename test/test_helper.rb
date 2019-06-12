# Load the normal Rails helper
require File.expand_path File.dirname(__FILE__) + '/../../../test/test_helper'

class ActiveSupport::TestCase
  def load_fixture(name)
    IO.read File.join File.dirname(__FILE__), 'fixtures', name
  end
end

require 'airbrake-ruby'
Airbrake.configure do |config|
  config.project_id = 1234
  config.project_key = {
    :project => 'ecookbook',
    :tracker => 'Bug',
    :api_key => 'asdfghjk',
  }.to_json
  config.host = 'http://localhost:3003'
  config.root_directory = Rails.root.to_s
end
