module RedmineAirbrake
  module Patches
    module IssuePatch

      def self.apply
        Issue.class_eval do
          attr_writer :notify
          prepend InstanceMethods
        end unless Issue < InstanceMethods
      end

      module InstanceMethods
        def notify?
          @notify != false
        end

        def send_notification
          super if notify?
        end
      end

    end
  end
end

