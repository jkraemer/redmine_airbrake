require 'psych'

module RedmineAirbrake
  module Notice

    class V2 < Base

      # in some constellations, symbols are not parsed as symbols but
      # instead, keys keep the leading ':'. We normalize that here
      def self.normalize_yaml_keys(hash)
        Hash[hash.map{|k,v| [k.sub(/\A:/,''), v]}]
      end

      def self.load_config(string)
        return {} if string.blank?

        config = JSON.parse(string) rescue {}
        if config.blank?
          config = normalize_yaml_keys Psych.safe_load(
            string,
            permitted_classes: [Symbol],
            permitted_symbols: %i[project tracker api_key category assigned_to author priority environment repository_root]).stringify_keys
        end
        config
      end

      def initialize(data)
        xml = Nokogiri::XML(data)
        cfg = xml.xpath('//api-key').first.content rescue ''
        @config = self.class.load_config cfg

        @errors = []
        xml.xpath('//error').each do |e|
          @errors << build_error(e)
        end

        @env = {}
        xml.xpath('//server-environment/*').each do |element|
          @env[element.name] = element.content
        end

        @request = {
          'params' => {},
          'cgi-data' => {}
        }
        xml.xpath('//request/*').each do |element|
          case element.name
          when 'params', 'cgi-data'
            @request[element.name] = parse_key_values(element.xpath('var'))
          else
            @request[element.name] = element.content
          end
        end
      end


      def build_error(xml)
        backtrace = []
        xml.xpath('backtrace/line').each do |line|
          backtrace << { 'line' => line['number'], 'file' => line['file'], 'function' => line['method'] }
        end
        Error.new({
            'class' => (xml.xpath('class').first.content rescue nil),
            'message' => (xml.xpath('message').first.content rescue nil),
            'backtrace' => backtrace
          }, self)
      end

      private

      def parse_key_values(xml)
        {}.tap do |result|
          xml.each do |element|
            result[element['key']] = element.content
          end
        end
      end

    end
  end
end
