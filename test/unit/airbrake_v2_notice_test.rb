require File.expand_path('../../test_helper', __FILE__)

class AirbrakeV2NoticeTest < ActiveSupport::TestCase

  test 'should have environment' do
    assert_equal 'staging', @notice.environment
  end

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
    assert_equal('Bug', params['tracker'], params.inspect)
    assert_equal('staging', params['environment'])
    assert_equal(5, params['priority'])
    assert_equal('ecookbook', params['project'])
    assert_equal('foobar', params['api_key'])
    assert_equal('/some/path', params['repository_root'])
  end

  test 'should parse server environment' do
    assert env = @notice.env
    assert_equal('/Users/jk/code/webit/etel/serviceportal', env['project-root'])
    assert_equal('production', env['environment-name'])
    assert_equal('blender.local', env['hostname'])
  end

  test 'should parse error' do
    assert_equal 1, @notice.errors.size
    assert error = @notice.errors.first
    assert_equal('RuntimeError', error.error_class)
    assert_equal('RuntimeError: pretty print me!', error.message)
    assert backtrace = error.backtrace
    assert backtrace.any?
    assert l = backtrace.first
    assert_equal('6', l['line'])
    assert_equal('[PROJECT_ROOT]/app/views/layouts/serviceportal.html.erb', l['file'])
    assert_equal('_run_erb_app47views47layouts47serviceportal46html46erb', l['function'])
    l = backtrace.last
    assert_equal('3', l['line'])
    assert_equal('', l['function'])
    assert_equal('script/server', l['file'])
  end

  test 'should parse request' do
    assert req = @notice.request
    assert_equal('https://cul8er.local:3001/', req['url'])
    assert_equal('meta', req['component'])
    assert_equal('index', req['action'])
    assert params = req['params']
    assert_equal('index', params['action'])
    assert_equal('meta', params['controller'])
    assert cgi = req['cgi-data']
    assert_equal('', cgi['rack.session'])
    assert_equal('text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8', cgi['HTTP_ACCEPT'])
  end

  def setup
    @notice = RedmineAirbrake::Notice::V2.new load_fixture 'v2_message.xml'
  end

end
