require 'fluent/mixin/config_placeholders'
module Fluent

  class SyslogOutput < Fluent::Output
    # First, register the plugin. NAME is the name of this plugin
    # and identifies the plugin in the configuration file.
    Fluent::Plugin.register_output('syslog', self)

    # This method is called before starting.

    config_param :remote_syslog, :string, :default => nil
    config_param :port, :integer, :default => 25
    config_param :hostname, :string, :default => ""
    config_param :remove_tag_prefix, :string, :default => nil
    config_param :tag_key, :string, :default => nil
    config_param :facility, :string, :default => 'user'
    config_param :severity, :string, :default => 'debug'
    config_param :use_record, :string, :default => nil
    config_param :payload_key, :string, :default => 'message'


    def initialize
      super
      require 'socket'
      require 'syslog_protocol'
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
        @packet.hostname = hostname
        if @use_record
          @packet.facility = record['facility'] || @facilty
          @packet.severity = record['severity'] || @severity
        else
          @packet.facility = @facilty
          @packet.severity = @severity
        end
        if record['time']
          time = Time.parse(record['time'])
        else
          time = Time.now
        end
        @packet.time = time
        @packet.tag = if @tag_key
                        begin
                          record[@tag_key][0..31].gsub(/[\[\]]/,'') # tag is trimmed to 32 chars for syslog_protocol gem compatibility
                        rescue
                          tag[0..31] # tag is trimmed to 32 chars for syslog_protocol gem compatibility
                        end
                      else
                          tag[0..31] # tag is trimmed to 32 chars for syslog_protocol gem compatibility
                      end
        packet = @packet.dup
        packet.content = record[@payload_key]
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
