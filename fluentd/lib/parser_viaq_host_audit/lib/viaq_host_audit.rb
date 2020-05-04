require 'fluent/plugin/input'
require 'time'

# Parses audit log to format that fits Origin Aggregated Logging
module Fluent
  class ViaqHostAudit

    class ViaqHostAuditParserException < StandardError
    end

    # Keys as found in raw audit.log messsages
    IN_TYPE = 'type'
    IN_MSG = 'msg'

    # Keys used in Origin Aggregated Logging schema
    OUT_HOST_TYPE = 'type'
    OUT_HOST_HOSTNAME = 'hostname'

    TIME = 'time'
    RECORD_ID = 'record_id'
    ENV_HOSTNAME = 'NODE_NAME'
    MSG = 'message'
    AUDIT_ENVELOPE = 'audit.linux'

    def initialize()
      @@hostname = ENV[ENV_HOSTNAME].nil? ? nil : String.new(ENV[ENV_HOSTNAME])
    end

    # Takes one line from audit.log and returns hash
    # that fits the OAL format.
    def parse_audit_line(line)
      event = {}
      parse_metadata(event, line.split)
      return normalize(event, line)
    end

    private

    def parse_metadata(result, metadata)
      # Parse audit record type
      result[IN_TYPE] = metadata[0].split('=')[1]

      # Parse audit record ID
      time_id = metadata[1].sub(/msg=audit\((?<g1>.*)\):/, '\k<g1>').split(':')
      result[TIME] = time_id[0]
      result[RECORD_ID] = time_id[1]
    end

    def normalize(target, message)
      event = {}
      event[TIME]              = Time.at(target[TIME].to_f).utc.to_datetime.rfc3339(6)
      event[OUT_HOST_HOSTNAME] = @@hostname unless @@hostname.nil?

      event[AUDIT_ENVELOPE] = {}
      event[AUDIT_ENVELOPE][OUT_HOST_TYPE] = target[IN_TYPE]
      event[AUDIT_ENVELOPE][RECORD_ID] = target[RECORD_ID]
      event[MSG] = message
      return event
    end

  end
end
