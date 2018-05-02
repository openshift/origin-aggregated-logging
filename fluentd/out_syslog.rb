#  License: MIT
#  https://github.com/docebo/fluent-plugin-remote-syslog

require 'fluent/mixin/config_placeholders'
module Fluent
  class SyslogOutput < Fluent::Output
    # First, register the plugin. NAME is the name of this plugin
    # and identifies the plugin in the configuration file.
    Fluent::Plugin.register_output('syslog', self)

    # This method is called before starting.

    config_param :remote_syslog, :string, :default => ""
    config_param :port, :integer, :default => 25
    config_param :hostname, :string, :default => ""
    config_param :remove_tag_prefix, :string, :default => nil
    config_param :tag_key, :array, default: []
    config_param :facility, :string, :default => 'user'
    config_param :severity, :string, :default => 'debug'
    config_param :use_record, :string, :default => nil
    config_param :payload_key, :string, :default => 'message'


    def initialize
      super
      require 'socket'
      require 'syslog_protocol'
      require 'securerandom'
    end

    def configure(conf)
      super
      if not conf['remote_syslog']
        raise Fluent::ConfigError.new("remote syslog required")
      end
      @socket = UDPSocket.new
      @packet = SyslogProtocol::Packet.new
      if remove_tag_prefix = conf['remove_tag_prefix']
          @remove_tag_prefix = Regexp.new('^' + Regexp.escape(remove_tag_prefix))
      end
      @facilty = conf['facility']
      @severity = conf['severity']
      @use_record = conf['use_record']
      @payload_key = conf['payload_key']
      if not @payload_key
        @payload_key = "message"
      end
      @random_string = SecureRandom.hex
    end


    # This method is called when starting.
    def start
      super
    end

    # This method is called when shutting down.
    def shutdown
      super
    end

    # This method is called when an event reaches Fluentd.
    # 'es' is a Fluent::EventStream object that includes multiple events.
    # You can use 'es.each {|time,record| ... }' to retrieve events.
    # 'chain' is an object that manages transactions. Call 'chain.next' at
    # appropriate points and rollback if it raises an exception.
    def emit(tag, es, chain)
      tag = tag.sub(@remove_tag_prefix, '') if @remove_tag_prefix
      chain.next
      es.each {|time,record|
        if @use_record
          @packet.hostname = record['hostname'] || hostname
          @packet.severity = (record['level'].eql? 'warning')? 'warn' : record['level'] || @severity
          if @use_record && record.key?('systemd') && (record['systemd']).key?('u') && (record['systemd']['u']).key?('SYSLOG_FACILITY')
            fval = record['systemd']['u']['SYSLOG_FACILITY'].to_i
            if (1..23).include?(fval)
              @packet.facility = fval
            else
              if record['systemd']['u']['SYSLOG_FACILITY'].eql? '0'
                @packet.facility = 0
              else
                @packet.facility = record['systemd']['u']['SYSLOG_FACILITY'] || @facility
              end
            end
          elsif record.key?('_KERNEL_DEVICE')
            @packet.facility = 'kern'
          else
            @packet.facility = record['facility'] || @facility
          end
        else
          @packet.hostname = hostname
          @packet.facility = @facilty
          @packet.severity = @severity
        end
        time = if record['time']
          Time.parse(record['time'])
        else
          Time.now
        end
        @packet.time = time
        @packet.tag = @random_string
        if !@tag_key.empty? && !record.empty?
          # tag_key is an array type
          # E.g., tag_key ident,systemd.u.SYSLOG_IDENTIFIER,ident
          #       tkey = ident
          #       tkey = systemd.u.SYSLOG_IDENTIFIER
          @tag_key.each { |tkey|
            # ident => record[ident]
            # systemd.u.SYSLOG_IDENTIFIER => record[systemd][u][SYSLOG_IDENTIFIER]
            mytag = record
            # check if tkey is '.' separated.
            tkey.split('.').each { |p|
              if ! mytag.key?(p)
                if ! p.eql? tkey
                  log.debug "out:syslog: #{p} from #{tkey} in tag_key #{@tag_key} is not a key of record."
                end
                break
              end
              mytag = mytag[p]
            }
            next if ! mytag.is_a? String
            @packet.tag = mytag[0..31].gsub(/[\[\]\s]/,'') # tag is trimmed to 32 chars for syslog_protocol gem compatibility
            break
          }
        end
        if @packet.tag.eql? random_string
          @packet.tag = tag[0..31] # tag is trimmed to 32 chars for syslog_protocol gem compatibility
        end
        packet = @packet.dup
        packet.content = if @use_record && (record.key?('kubernetes')) && record[@payload_key]
          (((record['kubernetes']).key?('namespace_name')) ? 'namespace_name=' + record['kubernetes']['namespace_name'] + ', ' : '' ) + \
          (((record['kubernetes']).key?('container_name')) ? 'container_name=' + record['kubernetes']['container_name'] + ', ' : '' ) + \
          (((record['kubernetes']).key?('pod_name')) ? 'pod_name=' + record['kubernetes']['pod_name'] + ', ' : '' ) + \
          @payload_key + '=' + record[@payload_key]
        else
          record[@payload_key]
        end
        @socket.send(packet.assemble, 0, @remote_syslog, @port)
    }
    end
  end
  class Time < Time
    def timezone(timezone = 'UTC')
      old = ENV['TZ']
      utc = self.dup.utc
      ENV['TZ'] = timezone
      output = utc.localtime
      ENV['TZ'] = old
      output
    end
  end

end
