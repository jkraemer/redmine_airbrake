module RedmineAirbrake
  module Notice

    class Base
      attr_reader :config, :errors, :env, :request, :session

      def api_key_valid?
        key = config['api_key']
        key.present? and key == Setting.mail_handler_api_key
      end

      # creates / updates the issue
      def save
        return false unless project and tracker and author

        if issue = Issue.where(subject: subject,
                               project_id: project.id,
                               tracker_id: tracker.id,
                               author_id: author.id).first

          if value = issue.custom_value_for(CustomFields.occurences)
            value.update_attribute :value, value.value.to_i + 1
          end

        else
          # create a new issue

          CustomFields.ensure_fields_on_tracker_and_project tracker, project

          cf_values = {
            CustomFields.error_class.id => error.error_class,
            CustomFields.occurences.id  => 1
          }
          if environment.present?
            cf_values[CustomFields.environment.id] = environment
          end

          issue = Issue.new project:     project,
                            tracker:     tracker,
                            author:      author,
                            assigned_to: assignee,
                            category:    category,
                            priority:    priority,
                            subject:     subject,
                            description: description,
                            custom_field_values: cf_values

          # do not send mails right now
          ::Mailer.with_deliveries(false) do
            issue.save!
          end

        end

        # create the journal entry, update issue attributes
        retried_once = false # we retry once in case of a StaleObjectError
        begin
          issue = Issue.find issue.id # otherwise the save below resets the custom value from above. Also should reduce the chance to run into the staleobject problem.
          # create journal
          issue.init_journal author, journal_text

          # reopen issue if needed
          if issue.status.blank? or issue.status.is_closed?
            issue.status = if Redmine::VERSION::MAJOR < 3
                             IssueStatus.default
                           else
                             issue.tracker.default_status
                           end
          end

          issue.save!
          return issue
        rescue ActiveRecord::StaleObjectError
          if retried_once
            Rails.logger.error "redmine_airbrake: failed to update issue #{issue.id} for the second time, giving up."
          else
            retried_once = true
            retry
          end
        end
        false
      end

      # errors is an array holding the exception's `cause` chain. First is the
      # exception we're handling, last the most inner one (up to a level of 3,
      # that's hardcoded in airbrake-ruby's NestedException)
      #
      # Any nested exceptions are appended to the journal text.
      def error
        errors.first
      end

      # remove [POJECT_PATH] or [GEM_PATH] from a path
      # works also with new format /PROJECT_PATH/ or /GEM_PATH/
      def cleanup_path(path)
        path.sub(/\A[\[\/][A-Z]+_ROOT\]?\//, '')
      end

      # issue subject
      def subject
        (environment.present? ? "[#{environment}] " : "").tap do |subj|
          subj << error.error_class
          if l = error.line
            path = cleanup_path(l['file'])
            path_len = 247 - (subj.length + l['line'].to_s.length)
            if path.length > path_len
              path = "...#{path[-1*path_len, path_len]}"
            end
            subj << " in #{path}:#{l['line']}"
          end
        end
      end

      # issue description including a link to source repository
      def description
        "Airbrake Notifier reported an Error".tap do |description|
          if l = error.line
            description << " related to source:#{repo_root}/#{cleanup_path l['file']}#L#{l['line']}"
          end
        end
      end

      def author
        @author ||= User.find_by_login(config["author"]) || User.anonymous
      end

      def journal_text
        JournalText.format self
      end

      def environment
        config['environment']
      end

      def category
        IssueCategory.find_by_name(config["category"]) unless config["category"].blank?
      end

      def assignee
        if name = config['assigned_to']
          User.find_by_login(name) || Group.find_by_lastname(name)
        end
      end

      def priority
        @priority ||= if prio = config['priority']
          IssuePriority.find prio.to_i
        else
          IssuePriority.default
        end
      end

      def project
        @project ||= Project.find_by_identifier config['project']
      end

      def tracker
        @tracker ||= project.trackers.find_by_name config['tracker']
      end

      def repo_root
        project.custom_value_for(CustomFields.repository_root).value.gsub(/\/$/,'') rescue nil
      end

      def error_class
        error.error_class
      end

      def error_message
        error.message
      end

    end

  end
end

