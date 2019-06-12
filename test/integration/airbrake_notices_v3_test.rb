# Load the normal Rails helper
require File.expand_path File.dirname(__FILE__) + '/../test_helper'

class AirbrakeNoticesV3Test < Redmine::IntegrationTest
  fixtures :projects, :users, :trackers, :projects_trackers, :enumerations, :issue_statuses

  setup do
    Setting.mail_handler_api_key = 'asdfghjk'
    @project = Project.find 1
    @tracker = @project.trackers.first
    @notice_hash = JSON.parse load_fixture "notice.json"
    RedmineAirbrake::CustomFields.clear_cache
  end

  test "should handle config as key param" do
    assert_difference "Issue.count", 1 do
      assert_difference "Journal.count", 1 do
        post '/api/v3/projects/1234/notices?key=%7B%22project%22%3A%22ecookbook%22%2C%22tracker%22%3A%22Bug%22%2C%22api_key%22%3A%22asdfghjk%22%7D',
          params: @notice_hash, as: :json
      end
    end
    assert_response :success
    check_issue
  end

  test "should handle config in Authorization header" do
    assert_difference "Issue.count", 1 do
      assert_difference "Journal.count", 1 do
        post '/api/v3/projects/1234/notices',
          params: @notice_hash, as: :json,
          headers: { "Authorization" => "Bearer #{CGI.escape config.to_json}" }
      end
    end
    assert_response :success
    check_issue
  end

  test 'should handle config as context parameters' do
    (@notice_hash[:context] ||= {})[:redmine_config] = config

    assert_difference "Issue.count", 1 do
      assert_difference "Journal.count", 1 do
        post '/api/v3/projects/1234/notices', params: @notice_hash, as: :json
      end
    end
    assert_response :success
    check_issue
  end

  test "should update existing issue" do
    (@notice_hash[:context] ||= {})[:redmine_config] = config

    assert_difference "Issue.count", 1 do
      assert_difference "Journal.count", 1 do
        post '/api/v3/projects/1234/notices', params: @notice_hash, as: :json
      end
    end
    assert_response :success
    assert_no_difference "Issue.count", 1 do
      assert_difference "Journal.count", 1 do
        post '/api/v3/projects/1234/notices', params: @notice_hash, as: :json
      end
    end
  end

  test "should render error for non existing project" do
    (@notice_hash[:context] ||= {})[:redmine_config] = config(project: "foo")
    assert_no_difference "Issue.count" do
      assert_no_difference "Journal.count" do
        post '/api/v3/projects/1234/notices', params: @notice_hash, as: :json
      end
    end
    assert_response 400
  end

  test "should render error for non existing tracker" do
    (@notice_hash[:context] ||= {})[:redmine_config] = config(tracker: "foo")
    assert_no_difference "Issue.count" do
      assert_no_difference "Journal.count" do
        post '/api/v3/projects/1234/notices', params: @notice_hash, as: :json
      end
    end
    assert_response 400
  end

  test "should require valid api key" do
    (@notice_hash[:context] ||= {})[:redmine_config] = config(api_key: "foo")
    assert_no_difference "Issue.count" do
      assert_no_difference "Journal.count" do
        post '/api/v3/projects/1234/notices', params: @notice_hash, as: :json
      end
    end
    assert_response 403
  end

  def check_issue
    assert issue = Issue.where("subject like ?", "%RuntimeError%").last
    assert_equal(1, issue.journals.size)
    assert_equal(5, issue.priority_id)
    assert occurences_field = IssueCustomField.find_by_name('# Occurences')
    assert occurences_value = issue.custom_value_for(occurences_field)
    assert_equal('1', occurences_value.value)
  end

  DEFAULT_CONFIG = {
    project: 'ecookbook',
    tracker: 'Bug',
    api_key: 'asdfghjk',
  }

  def config(cfg = {})
    DEFAULT_CONFIG.merge(cfg)
  end

end
