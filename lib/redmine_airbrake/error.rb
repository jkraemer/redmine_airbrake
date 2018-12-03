module RedmineAirbrake
  class Error

    TRACE_FILTERS = [
      /^On\sline\s#\d+\sof/,
      /^\d+:/
    ]

    attr_accessor :data
    def initialize(data, notice)
      @data = data
      @notice = notice
    end

    def error_class
      data['class'] || data['type']
    end

    def message
      data['message']
    end

    def backtrace
      @backtrace ||= data['backtrace'].compact
    end

    def filtered_backtrace
      unless project_trace_filter.blank?
        @filtered_backtrace ||= filter_backtrace backtrace
      end
    end

    # returns the first frame from the backtrace that's below PROJECT_ROOT (for
    # source linking)
    def line
      (filtered_backtrace || backtrace).detect do |frame|
        # We match both the old format [PROJECT_ROOT] and the new style /PROJECT_ROOT/
        frame['file'] =~ /\A(?:\[|\/)PROJECT_ROOT(?:\]|\/)/
      end
    end

    private

    def project_trace_filter
      @project_trace_filter ||= @notice.project.custom_value_for(CustomFields.trace_filter).value.lines.map(&:strip) rescue []
    end

    def filter_backtrace(backtrace)
      trace_filters = TRACE_FILTERS + project_trace_filter
      backtrace.reject do |frame|
        file = frame['file']
        file.blank? || trace_filters.any?{|expr| file[expr]}
      end
    end

  end
end
