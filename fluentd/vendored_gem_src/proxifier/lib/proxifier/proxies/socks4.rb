require "proxifier/proxies/socks"

module Proxifier
  class SOCKS4Proxy < SOCKSProxy
    VERSION = 0x04

    protected
      def greet(socket)
        # noop
      end

      def authenticate(socket, method)
        # noop
      end

      def connect(socket, host, port)
        begin
          ip = IPAddr.new(host)
        rescue ArgumentError
          ip = IPAddr.new(Socket.getaddrinfo(host, nil, :INET, :STREAM).first)
        end

        socket << [VERSION, 0x01, port].pack("CCn") << ip.hton
        socket << user if user
        socket << 0x00

        version, status, port = socket.read(4).unpack("CCn")
        check_version(version, 0x00)
        ip = IPAddr.ntop(socket.read(4))

        case status
        when 0x5A # request granted
        when 0x5B # request rejected or failed
          raise "request rejected or failed"
        when 0x5C # request rejected becasue SOCKS server cannot connect to identd on the client
          raise "request rejected becasue SOCKS server cannot connect to identd on the client"
        when 0x5D # request rejected because the client program and identd report different user-ids
          raise "request rejected because the client program and identd report different user-ids"
        else
          raise "unknown SOCKS error"
        end
      end
  end
end
