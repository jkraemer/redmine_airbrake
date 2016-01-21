require File.expand_path('../../test_helper', __FILE__)

class AirbrakeV2YamlNoticeTest < ActiveSupport::TestCase

  test 'should have environment' do
    assert_equal 'staging', @notice.environment
  end

  test 'should compute subject' do
    assert s = @notice.subject
    assert_match(/staging/, s)
    assert_match(/RuntimeError/, s)
    assert_match(/ in /, s)
  end

  test 'should check api key' do
    assert !@notice.api_key_valid?
    with_settings mail_handler_api_key: 'foobar' do
      assert @notice.api_key_valid?
    end
  end

  test 'should parse redmine params' do
    assert params = @notice.config
    assert_equal('Bug', params['tracker'], params.inspect)
    assert_equal('staging', params['environment'])
    assert_equal(5, params['priority'])
    assert_equal('ecookbook', params['project'])
    assert_equal('foobar', params['api_key'])
    assert_equal('/some/path', params['repository_root'])
  end


  def setup
    @notice = RedmineAirbrake::Notice::V2.new load_fixture 'v2_yaml_message.xml'
  end

end
