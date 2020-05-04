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
        time = parsed_line.nil? ? Time.now.to_f : DateTime.parse(parsed_line['time']).to_time.to_f

        yield time, parsed_line
      rescue Fluent::ViaqHostAudit::ViaqHostAuditParserException => e
        log.error e.message
        yield nil, nil
      end
    end
  end
end
