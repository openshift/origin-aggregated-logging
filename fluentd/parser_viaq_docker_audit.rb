require 'fluent/parser'
require 'fluent/time'

require_relative 'viaq_docker_audit'

module Fluent
  class ViaqDockerAuditParser < Parser
    Plugin.register_parser("viaq_docker_audit", self)

    def configure(conf={})
      super
      @audit_parser = ViaqDockerAudit.new()
    end

    def parse(text)
      begin
        parsed_line = @audit_parser.parse_audit_line text
        time = parsed_line.nil? ? Time.now.to_f : DateTime.parse(parsed_line['time']).to_time.to_f

        # All other logs than virt-control should be ignored.
        # Since this plugin is tailored specifically to atomic-project
        # docker audit log, it can not properly parse those.
        # A temporary solution is to mark unwanted messages as something
        # that is easy to find and exclude by the fluentd grep plugin.
        parsed_line = {"virt-control" => "false"} if parsed_line.nil?

        yield time, parsed_line
      rescue Fluent::ViaqDockerAudit::ViaqDockerAuditParserException => e
        log.error e.message
        yield nil, nil
      end
    end
  end
end
