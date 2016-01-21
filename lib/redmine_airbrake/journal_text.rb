require 'pp'

module RedmineAirbrake
  module JournalText

    def self.format(*args)
      if 'textile' == Setting.text_formatting
        Textile.new *args
      else
        Markdown.new *args
      end.text
    end

    class Formatter
      def initialize(notice, error = notice.error)
        @notice = notice
        @error = error
        @filtered_backtrace = error.filtered_backtrace
      end

      def text
        [
          ["Error message",      @error.message],
          ["Filtered backtrace", format_backtrace(@error.filtered_backtrace)],
          ["Request",            format_hash(@notice.request)],
          ["Session",            format_hash(@notice.session)],
          ["Environment",        format_hash(@notice.env)],
          ["Full backtrace",     format_backtrace(@error.backtrace)],
        ].map do |name, data|
          format_section name, data
        end.join
      end

      private

      def format_hash(hash)
        PP.pp hash, "" if hash
      end

      def format_backtrace(lines)
        unless lines.blank?
          lines.map do |l|
            "#{l['file']}:#{l['line']}#{':in '+l['function'] if l['function']}"
          end.join("\n")
        end
      end
    end

    class Textile < Formatter
      private

      def format_section(name, data)
        "h4. #{name}\n\n<pre>\n#{data}\n</pre>\n\n" unless data.blank?
      end
    end

    class Markdown < Formatter
      private

      def format_section(name, data)
        "#### #{name}\n\n#{indent data}\n\n" unless data.blank?
      end

      def indent(string)
        string.lines.map{|s|s.prepend "    "}.join
      end
    end

  end
end
