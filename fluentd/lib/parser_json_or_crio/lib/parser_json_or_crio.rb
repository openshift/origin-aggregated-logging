require 'fluent/parser'

module Fluent
  class ParserJsonOrCrio < Parser
    Plugin.register_parser("json_or_crio", self)

    config_param :crio_format, :string, default: '/^(?<time>.+) (?<stream>stdout|stderr)( (?<logtag>.))? (?<log>.*)$/'
    config_param :crio_time_format, :string, default: '%Y-%m-%dT%H:%M:%S.%N%:z'
    config_param :json_time_format, :string, default: '%Y-%m-%dT%H:%M:%S.%N%Z'

    def configure(conf={})
      super
      @crio_parser = Plugin.new_parser(@crio_format)
      conf['time_format'] = @crio_time_format
      @crio_parser.configure(conf)
      @json_parser = Plugin.new_parser('json')
      conf['time_format'] = @json_time_format
      @json_parser.configure(conf)
    end

    def parse(text)
      if text[0] == '{'.freeze && text[-1] == '}'.freeze
        time, record = @json_parser.call(text)
      else
        time, record = @crio_parser.call(text)
      end
      if block_given?
        yield time, record
        return
      else
        return time, record
      end
    end
  end
end
