# Load the normal Rails helper
require File.expand_path File.dirname(__FILE__) + '/../test_helper'

class AirbrakeNoticesV2Test < Redmine::IntegrationTest
  fixtures :projects, :users, :trackers, :projects_trackers, :enumerations, :issue_statuses

  setup do
    RedmineAirbrake::CustomFields.clear_cache
    ActionDispatch::IntegrationTest.register_encoder :xml,
      param_encoder: -> params { params }
  end

  test 'should create an issue with journal entry for a v2 request' do
    v2_test load_fixture('v2_message.xml')
  end

  test 'should create an issue with journal entry for a v2 request with yaml config' do
    v2_test load_fixture('v2_yaml_message.xml')
  end

  test 'should create an issue with journal entry for a v2 request with yaml config with symbol keys' do
    v2_test load_fixture('v2_yaml_symbols_message.xml')
  end


  def v2_test(data)
    with_settings mail_handler_api_key: 'foobar' do
      assert_difference "Issue.count", 1 do
        assert_difference "Journal.count", 1 do
          post '/api/v2/projects/1234/notices', params: data, as: :xml
        end
      end
      assert_response :success
      assert issue = Issue.where(subject: '[staging] RuntimeError in app/views/layouts/serviceportal.html.erb:6').first
      assert_equal(1, issue.journals.size)
      assert_equal(5, issue.priority_id)
      assert occurences_field = IssueCustomField.find_by_name('# Occurences')
      assert occurences_value = issue.custom_value_for(occurences_field)
      assert_equal('1', occurences_value.value)


      assert_no_difference 'Issue.count' do
        assert_difference "Journal.count", 1 do
          post '/api/v2/projects/1234/notices', params: data, as: :xml
        end
      end
      occurences_value.reload
      assert_equal('2', occurences_value.value)
    end
  end

end
