require File.expand_path('../../test_helper', __FILE__)

class AirbrakeV3NoticeTest < ActiveSupport::TestCase

  test 'should compute subject' do
    assert s = @notice.subject
    assert_match(/staging/, s)
    assert_match(/RuntimeError/, s)
    assert_match(/ in /, s)
  end

  test 'should compute description' do
    assert d = @notice.description
    assert_match(/Airbrake Notifier reported/, d)
    assert_match(/source:\//, d)
  end

  test 'should compute journal text for textile' do
    with_settings text_formatting: 'textile' do
      assert t = @notice.journal_text
      assert_match(/^h4\./, t)
    end
  end

  test 'should compute journal text for markdown' do
    with_settings text_formatting: 'markdown' do
      assert t = @notice.journal_text
      assert_match(/^####/, t)
    end
  end

  test 'should check api key' do
    assert !@notice.api_key_valid?
    with_settings mail_handler_api_key: 'foobar' do
      assert @notice.api_key_valid?
    end
  end

  test 'should parse redmine params' do
    assert params = @notice.config
    assert_equal('Exception', params['tracker'], params.inspect)
    assert_equal('staging', params['environment'])
    assert_equal(5, params['priority'])
    assert_equal('ecookbook', params['project'])
    assert_equal('foobar', params['api_key'])
    assert_equal('/some/path', params['repository_root'])
  end

  test 'should parse error' do
    assert_equal 1, @notice.errors.size
    assert error = @notice.errors.first
    assert_equal('RuntimeError', error.error_class)
    assert_equal('test', error.message)
    assert backtrace = error.backtrace
    assert backtrace.any?
    assert l = backtrace.first
    assert_equal(71, l['line'])
    assert_equal('/home/jk/code/redmine/redmine/plugins/redmine_airbrake/test/functional/airbrake_notices_controller_test.rb', l['file'])
    assert_equal('create_error', l['function'])
  end

  def setup
    @notice = RedmineAirbrake::Notice::V3.new(
      load_fixture('v3_message.json'),
      { 'environment' => 'staging',
        'project' => 'ecookbook',
        'api_key' => 'foobar',
        'tracker' => 'Exception',
        'priority' => 5,
        'repository_root' => '/some/path'
      }
    )
  end

end

