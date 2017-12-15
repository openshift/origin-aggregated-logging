require 'time'

# Parses docker audit log to format that fits Origin Aggregated Logging
module Fluent
  class ViaqDockerAudit

    class ViaqDockerAuditParserException < StandardError
    end

    # Keys as found in raw audit.log messsages
    IN_HOST_PID = 'pid'
    IN_HOST_UID = 'uid'
    IN_HOST_AUID = 'auid'
    IN_HOST_SESSION = 'ses'
    IN_HOST_SELINUX_LABEL = 'subj'
    IN_HOST_HOSTNAME = 'hostname'
    IN_VM_AUID = 'auid'
    IN_VM_HOSTNAME = 'hostname'
    IN_VM_IMAGE = 'vm'
    IN_VM_PID = 'vm-pid'
    IN_VM_USER = 'user'
    IN_VM_EXE = 'exe'
    IN_VM_REASON = 'reason'
    IN_VM_OPERATION = 'op'
    IN_VM_RESULT = 'res'
    IN_EVENT_TYPE = 'virt_control'

    # Keys used in Origin Aggregated Logging schema
    OUT_HOST_PID = 'PID'
    OUT_HOST_UID = 'UID'
    OUT_HOST_AUID = 'AUDIT_LOGINUID'
    OUT_HOST_SESSION = 'AUDIT_SESSION'
    OUT_HOST_SELINUX_LABEL = 'SELINUX_CONTEXT'
    OUT_HOST_HOSTNAME = 'hostname'
    OUT_HOST_EXE = 'EXE'
    OUT_VM_AUID = 'sauid'
    OUT_VM_CONT_ID  = 'container_id_short'
    OUT_VM_IMAGE = 'container_image'
    OUT_VM_PID = 'pid'
    OUT_VM_USER = 'user'
    OUT_VM_COMMAND = 'command'
    OUT_VM_REASON = 'reason'
    OUT_VM_OPERATION = 'operation'
    OUT_VM_RESULT = 'result'

    TIME = 'time'
    SYSTEMD = 'systemd'
    TRUSTED = 't'
    DOCKER = 'docker'
    VIRT_CONTROL = 'VIRT_CONTROL'
    ENV_HOSTNAME = 'NODE_NAME'
    
    def initialize()
      @@hostname = ENV[ENV_HOSTNAME].nil? ? nil : String.new(ENV[ENV_HOSTNAME])
    end

    # Takes one line from audit.log and returns hash
    # that fits the OAL format.
    # Messages of other types than 'virt_control' are ignored.
    def parse_audit_line(line)
      if filter_virt_control(line)
        event = {}
        docker = {}
        if (metadata = /(?<g1>.*?) msg='(?<g2>.*?)'/.match(line)) && !metadata['g1'].nil? && !metadata['g2'].nil?
          parse_metadata(event, metadata['g1'].split)
          parse_msg(docker, metadata['g2'].split)
          event[IN_EVENT_TYPE] = docker
        else
          raise ViaqDockerAuditParserException, "Couldn't parse message: #{line}"
        end
        return normalize(event)
      end
      return nil
    end

    private

    def filter_virt_control(line)
      return (type = /^type=(?<type>[a-zA-Z_]+)/.match(line)) && type['type'] == VIRT_CONTROL && \
      /\/usr\/bin\/dockerd-current/.match(line)
    end

    def parse_metadata(result, metadata)
      result[TIME] = metadata[1].sub(/msg=audit\((?<g1>.*):\d+\):/, '\k<g1>')
      for i in 2...metadata.length
        pair = metadata[i].split('=')
        insert_or_merge(result, pair[0], pair[1]) unless pair[1].nil? or pair[1] == '?'
      end
    end

    def parse_msg(result, msg)
      msg.each do |part|
        pair = part.split('=')
        insert_or_merge(result, pair[0], pair[1]) unless pair[1].nil? or pair[1] == '?'
      end
    end

    def insert_or_merge(result, key, value)
      if result[key].nil?
        result[key] = value
      elsif result[key].kind_of?(Array)
        result[key] << value
      else
        temp = result[key]
        result[key] = [value, temp]
      end
    end

    def normalize(target)
      event = {}
      event[TIME]              = Time.at(target[TIME].to_f).utc.to_datetime.rfc3339(6)
      event[OUT_HOST_HOSTNAME] = @@hostname unless @@hostname.nil?

      event[SYSTEMD] = { TRUSTED => {} }
      event[SYSTEMD][TRUSTED][OUT_HOST_PID]           = target[IN_HOST_PID] unless target[IN_HOST_PID].nil?
      event[SYSTEMD][TRUSTED][OUT_HOST_UID]           = target[IN_HOST_UID] unless target[IN_HOST_UID].nil?
      event[SYSTEMD][TRUSTED][OUT_HOST_AUID]          = target[IN_HOST_AUID] unless target[IN_HOST_AUID].nil?
      event[SYSTEMD][TRUSTED][OUT_HOST_SESSION]       = target[IN_HOST_SESSION] unless target[IN_HOST_SESSION].nil?
      event[SYSTEMD][TRUSTED][OUT_HOST_SELINUX_LABEL] = target[IN_HOST_SELINUX_LABEL] unless target[IN_HOST_SELINUX_LABEL].nil?
      
      event[DOCKER] = {}
      event[DOCKER][OUT_VM_AUID]      = target[IN_EVENT_TYPE][IN_VM_AUID] unless target[IN_EVENT_TYPE][IN_VM_AUID].nil?
      event[DOCKER][OUT_VM_CONT_ID]   = target[IN_EVENT_TYPE][IN_VM_HOSTNAME] unless target[IN_EVENT_TYPE][IN_VM_HOSTNAME].nil?
      event[DOCKER][OUT_VM_IMAGE]     = target[IN_EVENT_TYPE][IN_VM_IMAGE] unless target[IN_EVENT_TYPE][IN_VM_IMAGE].nil?
      event[DOCKER][OUT_VM_PID]       = target[IN_EVENT_TYPE][IN_VM_PID] unless target[IN_EVENT_TYPE][IN_VM_PID].nil?
      event[DOCKER][OUT_VM_USER]      = target[IN_EVENT_TYPE][IN_VM_USER] unless target[IN_EVENT_TYPE][IN_VM_USER].nil?
      event[DOCKER][OUT_VM_REASON]    = target[IN_EVENT_TYPE][IN_VM_REASON] unless target[IN_EVENT_TYPE][IN_VM_REASON].nil?
      event[DOCKER][OUT_VM_OPERATION] = target[IN_EVENT_TYPE][IN_VM_OPERATION] unless target[IN_EVENT_TYPE][IN_VM_OPERATION].nil?
      event[DOCKER][OUT_VM_RESULT]    = target[IN_EVENT_TYPE][IN_VM_RESULT] unless target[IN_EVENT_TYPE][IN_VM_RESULT].nil?

      # raw audit.log duplicates 'exe' key
      if !target[IN_EVENT_TYPE][IN_VM_EXE].nil?
        exe_a = dedup_exe(target[IN_EVENT_TYPE][IN_VM_EXE])
        event[SYSTEMD][TRUSTED][OUT_HOST_EXE] = exe_a[0] unless exe_a[0].nil?
        event[DOCKER][OUT_VM_COMMAND]         = exe_a[1] unless exe_a[1].nil?
      end
      return event
    end

    def dedup_exe(field)
      event_exe = field
      docker_command = nil
      if field.kind_of?(Array)
        field.each do |f|
          if /dockerd-current/.match(f)
            event_exe = f
          else
            docker_command = f
          end
        end
      end
      return event_exe, docker_command
    end

  end
end
