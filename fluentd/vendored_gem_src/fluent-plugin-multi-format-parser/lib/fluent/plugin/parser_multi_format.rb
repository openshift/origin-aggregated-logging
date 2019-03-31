require 'fluent/plugin/parser'

module Fluent
  module Plugin
    class MultiFormatParser < Parser
      Plugin.register_parser('multi_format', self)

      def initialize
        super

        @parsers = []
      end

      def configure(conf)
        super

        conf.elements.each { |e|
          next unless ['pattern', 'format'].include?(e.name)
          next if e['format'].nil? && (e['@type'] == 'multi_format')

          parser = Plugin.new_parser(e['format'])
          parser.configure(e)
          @parsers << parser
        }
      end

      def parse(text)
        @parsers.each { |parser|
          begin
            parser.parse(text) { |time, record|
              if time && record
                yield time, record
                return
              end
            }
          rescue # ignore parser error
          end
        }

        yield nil, nil
      end
    end
  end
end
