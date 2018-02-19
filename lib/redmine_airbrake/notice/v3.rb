module RedmineAirbrake
  module Notice

    class V3 < Base

      def initialize(data, config = nil)
        @config = config
        @data = JSON.parse data

        @env = @data['environment']

        if ctx = @data['context']
          if config = ctx.delete('redmine_config')
            @config = config
          end
          @env['context'] = ctx
        end

        if errors = @data['errors']
          @errors = errors.map do |e|
            Error.new e, self
          end
        end

        if @request = @data['params']
          @request.delete 'thread' # newer airbrakes put a lot of stuff in there
        end
        @session = @data['session']

      end

    end
  end
end

