#  License: MIT
#  https://github.com/docebo/fluent-plugin-remote-syslog

require 'fluent/mixin/config_placeholders'
module Fluent
  class SyslogBufferedOutput < Fluent::BufferedOutput
    # First, register the plugin. NAME is the name of this plugin
    # and identifies the plugin in the configuration file.
    Fluent::Plugin.register_output('syslog_buffered', self)

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
      require 'timeout'
      require 'securerandom'
    end

    def configure(conf)
      super
      if not conf['remote_syslog']
        raise Fluent::ConfigError.new("remote syslog required")
      end
      @socket = create_tcp_socket(conf['remote_syslog'], conf['port'])
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

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def create_tcp_socket(host, port)
      begin
        Timeout.timeout(10) do
          begin
            socket = TCPSocket.new(host, port)
          rescue Errno::ENETUNREACH
            retry
          end
        end
        socket = TCPSocket.new(host, port)
        secs = Integer(1)
        usecs = Integer((1 - secs) * 1_000_000)
        optval = [secs, usecs].pack("l_2")
        socket.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval
      rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EPIPE, Timeout::Error, OpenSSL::SSL::SSLError, Timeout::Error => e
        log.warn "out:syslog: failed to open tcp socket  #{@remote_syslog}:#{@port} :#{e}"
        socket = nil
      end
      socket
    end

    # This method is called when starting.
    def start
      super
    end

    # This method is called when shutting down.
    def shutdown
      super
    end


    def write(chunk)
      chunk.msgpack_each {|(tag,time,record)|
        send_to_syslog(tag, time, record)
      }
    end

    def send_to_syslog(tag, time, record)
      tag = tag.sub(@remove_tag_prefix, '') if @remove_tag_prefix
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
                log.debug "out:syslog_buffered: #{p} from #{tkey} in tag_key #{@tag_key} is not a key of record."
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
      if @packet.tag.eql? @random_string
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
      begin
        if not @socket
          @socket = create_tcp_socket(@remote_syslog, @port)
        end
        if @socket
          begin
            @socket.write packet.assemble + "\n"
            @socket.flush
          rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EPIPE, Timeout::Error, OpenSSL::SSL::SSLError => e
            log.warn "out:syslog: connection error by #{@remote_syslog}:#{@port} :#{e}"
            @socket = nil
            raise #{e}
          end
        else
          log.warn "out:syslog: Socket connection couldn't be reestablished"
          raise #{e}
        end
      end
    end
  end
end

