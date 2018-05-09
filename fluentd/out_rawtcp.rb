# coding: utf-8
# 
# License: Apache2
# https://github.com/uken/fluent-plugin-out_rawtcp

module Fluent
  class RawTcpOutput < BufferedOutput
    Plugin.register_output('rawtcp', self)

    def initialize
      super
      require 'socket'
      require 'timeout'
      require 'fileutils'
      @nodes = []  #=> [Node]
    end

    config_param :send_timeout, :time, :default => 60
    config_param :connect_timeout, :time, :default => 5
    config_param :output_type, :string, :default => "msgpack"
    config_param :output_append_newline, :bool, :default => false
    attr_reader :nodes

    def configure(conf)
      super

      conf.elements.each do |e|
        next if e.name != "server"

        host = e['host']
        port = e['port']
        port = port ? port.to_i : DEFAULT_LISTEN_PORT

        name = e['name']
        unless name
          name = "#{host}:#{port}"
        end

        @nodes << RawNode.new(name, host, port)
        log.info "adding forwarding server '#{name}'", :host=>host, :port=>port
      end
    end

    def start
      super
    end

    def shutdown
      super
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def write(chunk)
      return if chunk.empty?

      error = nil

      @nodes.each do |node|
        begin
          send_data(node, chunk)
          return
        rescue
          error = $!
        end
      end

      raise error if error
      raise "No nodes available"
    end

    private
    def send_data(node, chunk)
      sock = connect(node)
      begin
        opt = [1, @send_timeout.to_i].pack('I!I!')  # { int l_onoff; int l_linger; }
        sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_LINGER, opt)

        opt = [@send_timeout.to_i, 0].pack('L!L!')  # struct timeval
        sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, opt)

        chunk.msgpack_each do |tag, time, record|
          next unless record.is_a? Hash
          sock.write(prepare_data_to_send(tag, time, record))
        end
      ensure
        sock.close
      end
    end

    def prepare_data_to_send(tag, time, record)
      if @output_type == "json"
        new_line_suf = ""
        if @output_append_newline
          new_line_suf = "\n"
        end
        return "#{record.to_json}#{new_line_suf}"
      else
        return [tag, time, record].to_msgpack
      end
    end

    def connect(node)
      Timeout.timeout(@connect_timeout) do
        return TCPSocket.new(node.resolved_host, node.port)
      end
    end

    class RawNode
      attr_reader :name, :host, :port

      def initialize(name, host, port)
        @name = name
        @host = host
        @port = port
        resolved_host
      end

      def resolved_host
        @sockaddr = Socket.pack_sockaddr_in(@port, @host)
        _, rhost = Socket.unpack_sockaddr_in(@sockaddr)
        rhost
      end
    end
  end
end

