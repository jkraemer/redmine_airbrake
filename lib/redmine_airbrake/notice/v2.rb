module RedmineAirbrake
  module Notice

    class V2 < Base

      def initialize(data)
        xml = Nokogiri::XML(data)
        cfg = xml.xpath('//api-key').first.content rescue ''
        @config = JSON.parse(cfg) rescue {}
        if @config.blank? && defined? SafeYAML
          @config = Hash[SafeYAML.load(cfg).map{|k,v| [k.to_s.sub( /\A:/,''), v]}]
        end


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
