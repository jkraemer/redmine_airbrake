module RedmineAirbrake
  module Notice

    class V3 < Base

      def initialize(data, config)
        @config = config
        @data = JSON.parse data

        if errors = @data['errors']
          @errors = errors.map do |e|
            Error.new e, self
          end
        end

        if @request = @data['params']
          @request.delete 'thread' # newer airbrakes put a lot of stuff in there
        end
        @session = @data['session']
        @env = @data['environment']
        @env['context'] = @data['context']

      end

    end
  end
end

