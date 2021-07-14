require 'fluent/plugin/input'
require 'time'

# Parses audit log to format that fits Origin Aggregated Logging
module Fluent
  class ViaqOvnAudit

    class ViaqOvnAuditParserException < StandardError
    end

    # Keys as found in raw audit.log messsages
    IN_TYPE = 'type'
    IN_MSG = 'msg'

    # Keys used in Origin Aggregated Logging schema
    OUT_HOST_TYPE = 'type'
    OUT_HOST_HOSTNAME = 'hostname'

    TIME = '@timestamp'
    LEVEL = 'level'
    ENV_HOSTNAME = 'NODE_NAME'
    AUDIT_ENVELOPE = 'structured'

    def initialize()
      @@hostname = ENV[ENV_HOSTNAME].nil? ? nil : String.new(ENV[ENV_HOSTNAME])
    end

    # Takes one line from audit.log and returns hash
    # that fits the OAL format.
    def parse_audit_line(line)
      puts line.inspect
      event = {}
      return normalize(event, line.split('|'))
    end

    private

    # Parses metadata and extract key values
    def normalize(target, metadata)
      event = {}
      event[TIME]              = metadata[0]
      event[LEVEL]             = metadata[3].downcase
      event[OUT_HOST_HOSTNAME] = @@hostname unless @@hostname.nil?

      event[AUDIT_ENVELOPE] = {}
      key_value =  metadata[4].split(',')

      key_value.each do |pair|
          key = pair.split('=')[0].strip
          value = pair.split('=')[1].strip
          event[AUDIT_ENVELOPE][key] = value
      end
      return event
    end

  end
end
