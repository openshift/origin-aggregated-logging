require 'fluent/parser'
require 'fluent/time'

require_relative 'viaq_host_audit'

module Fluent
  class ViaqHostAuditParser < Parser
    Plugin.register_parser("viaq_host_audit", self)

    def configure(conf={})
      super
      @audit_parser = ViaqHostAudit.new()
    end

    def parse(text)
      begin
        parsed_line = @audit_parser.parse_audit_line text
        
        if parsed_line.nil?
          t = Time.now
          time = Fluent::EventTime.new(t.to_i, t.nsec)
        else
          t = DateTime.parse(parsed_line['time']).to_time
          time = Fluent::EventTime.new(t.to_i, t.nsec)
        end

        yield time, parsed_line
      rescue Fluent::ViaqHostAudit::ViaqHostAuditParserException => e
        log.error e.message
        yield nil, nil
      end
    end
  end
end
