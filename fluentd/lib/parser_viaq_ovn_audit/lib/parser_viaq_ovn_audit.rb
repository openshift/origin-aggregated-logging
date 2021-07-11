require 'fluent/parser'
require 'fluent/time'

require_relative 'viaq_ovn_audit'

module Fluent
  class ViaqOvnAuditParser < Parser
    Plugin.register_parser("viaq_ovn_audit", self)

    def configure(conf={})
      super
      @audit_parser = ViaqOvnAudit.new()
    end

    def parse(text)
      begin
        parsed_json = @audit_parser.parse_audit_line text
        
        if parsed_json.nil?
          t = Time.now
          time = Fluent::EventTime.new(t.to_i, t.nsec)
        else
          t = DateTime.parse(parsed_json['@timestamp']).to_time
          time = Fluent::EventTime.new(t.to_i, t.nsec)
        end

        yield time, parsed_json
      rescue Fluent::ViaqOvnAudit::ViaqOvnAuditParserException => e
        log.error e.message
        yield nil, nil
      end
    end
  end
end
