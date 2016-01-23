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

  test 'should not have filtered backtrace when no filters are present' do
    @error.stubs(:project_trace_filter).returns(nil)
    assert_nil @error.filtered_backtrace
  end

  test 'should have filtered backtrace' do
    @error.stubs(:project_trace_filter).returns(['[GEM_ROOT]','foo'])
    assert backtrace = @error.backtrace
    assert backtrace.any?
    assert backtrace.any?{|frame| frame['file'] =~ /GEM_ROOT/}
    assert f_backtrace = @error.filtered_backtrace
    assert f_backtrace.any?
    assert !f_backtrace.any?{|frame| frame['file'] =~ /GEM_ROOT/}
  end

end
