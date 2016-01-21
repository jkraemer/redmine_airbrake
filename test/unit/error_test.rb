require File.expand_path('../../test_helper', __FILE__)

class ErrorTest < ActiveSupport::TestCase

  def setup
    @error = RedmineAirbrake::Notice::V2.new(load_fixture('v2_message.xml')).error
  end

  test 'should have error class' do
    assert_equal 'RuntimeError', @error.error_class
  end

  test 'should have error_message' do
    assert msg = @error.message
    assert_match(/pretty print/, msg)
  end

  test 'should have back trace' do
    assert backtrace = @error.backtrace
    assert backtrace.size > 0
  end

  test 'should have line' do
    assert @error.line.present?
  end

  test 'should have filtered back trace' do
    @error.stubs(:project_trace_filter).returns(['GEM_ROOT'])
    assert backtrace = @error.backtrace
    assert f_backtrace = @error.filtered_backtrace
    assert f_backtrace.size > 0
    assert f_backtrace.size < backtrace.size
  end

end
