require 'fluent/formatter'

module Fluent
  module TextFormatter
    class GELFFormatter < Formatter

      unless method_defined?(:log)
        define_method('log') { $log }
      end

      Plugin.register_formatter("gelf", self)

      require 'fluent/gelf_util'
      include GelfUtil

      config_param :use_record_host, :bool, :default => true
      config_param :add_msec_time, :bool, :default => false

      def configure(conf)
        super(conf)
      end

      def format(tag, time, record)

        begin

          gelfentry = make_gelfentry(
            tag,time,record,
            {
              :use_record_host => @use_record_host,
              :add_msec_time => @add_msec_time
            }
          )

          make_json(gelfentry,{})
      
        rescue Exception => e
          log.error sprintf(
            'Error trying to serialize %s: %s',
            record.to_s.force_encoding('UTF-8'),
            e.message.to_s.force_encoding('UTF-8')
          )
        end
      end

    end
  end
end
