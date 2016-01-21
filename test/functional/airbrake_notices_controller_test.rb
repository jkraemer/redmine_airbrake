require File.expand_path('../../test_helper', __FILE__)
require File.expand_path('../../../app/controllers/airbrake_notices_controller', __FILE__)

class AirbrakeNoticesControllerTest < ActionController::TestCase
  tests AirbrakeNoticesController

  fixtures :projects, :users, :trackers, :projects_trackers, :enumerations, :issue_statuses

  def setup
    Setting.mail_handler_api_key = 'asdfghjk'
    @project = Project.find 1
    @tracker = @project.trackers.first
    RedmineAirbrake::CustomFields.clear_cache
  end

  test 'should require valid api key' do
    assert_no_difference 'Issue.count' do
      raw_post :create, airbrake_params(api_key: 'wrong'), create_error
    end
    assert_response 403
  end

  test 'should create an issue with journal entry for a v2 request' do
    v2_test load_fixture('v2_message.xml')
  end

  test 'should create an issue with journal entry for a v2 request with yaml config' do
    v2_test load_fixture('v2_yaml_message.xml')
  end


  def v2_test(data)
    with_settings mail_handler_api_key: 'foobar' do
      assert_difference "Issue.count", 1 do
        assert_difference "Journal.count", 1 do
          raw_post :create, { version: 'v2' }, data
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
          raw_post :create, { version: 'v2' }, load_fixture('v2_yaml_message.xml')
        end
      end
      occurences_value.reload
      assert_equal('2', occurences_value.value)
    end
  end

  test 'should create an issue with journal entry' do
    assert_difference "Issue.count", 1 do
      assert_difference "Journal.count", 1 do
        raw_post :create, airbrake_params, create_error
      end
    end
    assert_response :success
    assert issue = Issue.where("subject like ?",
                                'RuntimeError in plugins/redmine_airbrake/test/functional/airbrake_notices_controller_test.rb%'
                              ).first
    assert_equal(1, issue.journals.size)
    assert_equal(5, issue.priority_id)
    assert occurences_field = IssueCustomField.find_by_name('# Occurences')
    assert occurences_value = issue.custom_value_for(occurences_field)
    assert_equal('1', occurences_value.value)


    assert_no_difference 'Issue.count' do
      assert_difference "Journal.count", 1 do
        raw_post :create, airbrake_params, create_error
      end
    end
    occurences_value.reload
    assert_equal('2', occurences_value.value)
  end

  test "should render error for non existing project" do
    assert_no_difference "Issue.count" do
      assert_no_difference "Journal.count" do
        raw_post :create, airbrake_params(project: 'unknown'), create_error
      end
    end
    assert_response 400
  end

  test "should render error for non existing tracker" do
    assert_no_difference "Issue.count" do
      assert_no_difference "Journal.count" do
        raw_post :create, airbrake_params(tracker: 'unknown'), create_error
      end
    end
    assert_response 400
  end

  def airbrake_params(cfg = {})
    {version: 'v3', key: config(cfg)}
  end


  attr_writer :airbrake_notice
  class TestSender
    def initialize(testcase)
      @testcase = testcase
    end
    def send(notice)
      @testcase.airbrake_notice = notice
    end
  end

  def create_error(cfg = {})
    raise 'test'
  rescue
    Airbrake::Notifier.new(project_id: 1234, project_key: config(cfg), root_directory: Rails.root.to_s).send(:send_notice, $!, {}, TestSender.new(self))
    return @airbrake_notice.to_json
  end

  def config(cfg)
    {
      project: 'ecookbook',
      tracker: 'Bug',
      api_key: 'asdfghjk',
    }.merge(cfg).to_json
  end

end
