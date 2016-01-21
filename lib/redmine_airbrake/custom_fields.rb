module RedmineAirbrake
  module CustomFields
    class << self

      def ensure_fields_on_tracker_and_project(tracker, project)
        [error_class, occurences, environment].each do |field|
          tracker.custom_fields << field unless tracker.custom_fields.include?(field)
          project.issue_custom_fields << field unless project.issue_custom_fields.include?(field)
        end
      end

      def error_class
        @error_class ||= issue_custom_field_for 'Error class', {
          field_format: 'string',
          searchable: true,
          is_filter: true
        }
      end

      def occurences
        @occurences ||= issue_custom_field_for '# Occurences', {
          field_format: 'int',
          default_value: 0,
          is_filter: true
        }
      end

      def environment
        @environment ||= issue_custom_field_for 'Environment', {
          field_format: 'string',
          searchable: true,
          is_filter: true
        }
      end

      def trace_filter
        @trace_filter ||= project_custom_field_for 'Backtrace filter', {
          field_format: 'text'
        }
      end

      def repository_root
        @repository_root ||= project_custom_field_for 'Repository root', {
          field_format: 'string'
        }
      end

      # necessary for test cases
      def clear_cache
        @repository_root = @trace_filter = @environment = @occurences = @error_class = nil
      end

      private

      def issue_custom_field_for(name, attributes = {})
        find_or_create_field IssueCustomField, name, attributes
      end

      def project_custom_field_for(name, attributes = {})
        find_or_create_field ProjectCustomField, name, attributes
      end

      def find_or_create_field(clazz, name, attributes = {})
        if Rails::VERSION::MAJOR == 3
          clazz.find_or_initialize_by_name name
        else
          clazz.find_or_initialize_by name: name
        end.tap do |f|
          if f.new_record?
            f.attributes = attributes
            f.save!
          end
        end
      end

    end
  end
end
