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
      data['backtrace']
    end

    def filtered_backtrace
      @filtered_backtrace ||= filter_backtrace backtrace
    end

    def line
      filtered_backtrace.first
    end

    private

    def project_trace_filter
      notice.project.custom_value_for(CustomFields.trace_filter).value.split(/[,\s\n\r]+/) rescue []
    end

    def filter_backtrace(backtrace)
      trace_filters = TRACE_FILTERS + project_trace_filter
      backtrace.reject do |line|
        file = line['file']
        file.blank? || trace_filters.any?{|expr| file.scan(expr).any?}
      end
    end

  end
end
