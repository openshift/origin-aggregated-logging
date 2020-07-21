require "ipaddr"
require "proxifier/proxy"

module Proxifier
  class SOCKSProxy < Proxy
    VERSION = 0x05

    def do_proxify(socket, host, port)
      authenticaton_method = greet(socket)
      authenticate(socket, authenticaton_method)
      connect(socket, host, port)
    end

    protected
      def greet(socket)
        methods = authentication_methods

        socket << [VERSION, methods.size, *methods].pack("CCC#{methods.size}")
        version, authentication_method = socket.read(2).unpack("CC")
        check_version(version)

        authentication_method
      end

      def authenticate(socket, method)
        case method
        when 0x00 # NO AUTHENTICATION REQUIRED
        when 0x02 # USERNAME/PASSWORD
          user &&= user[0, 0xFF]
          password &&= password[0, 0xFF]

          socket << [user.size, user, password.size, password].pack("CA#{user.size}CA#{password.size}")
          version, status = socket.read(2).unpack("CC")
          check_version(version)

          case status
            when 0x00 # SUCCESS
            else
              raise "SOCKS5 username/password authentication failed"
          end
        else
          raise "no acceptable SOCKS5 authentication methods"
        end
      end

      def connect(socket, host, port)
        host = host[0, 0xFF]
        socket << [VERSION, 0x01, 0x00, 0x03, host.size, host, port].pack("CCCCCA#{host.size}n")
        version, status, _, type = socket.read(4).unpack("CCCC")
        check_version(version)

        case status
        when 0x00 # succeeded
        when 0x01 # general SOCKS server failure
          raise "general SOCKS server failure"
        when 0x02 # connection not allowed by ruleset
          raise "connection not allowed by ruleset"
        when 0x03 # Network unreachable
          raise "network unreachable"
        when 0x04 # Host unreachable
          raise "host unreachable"
        when 0x05 # Connection refused
          raise "connection refused"
        when 0x06 # TTL expired
          raise "TTL expired"
        when 0x07 # Command not supported
          raise "command not supported"
        when 0x08 # Address type not supported
          raise "address type not supported"
        else      # unassigned
          raise "unknown SOCKS error"
        end

        case type
        when 0x01 # IP V4 address
          destination = IPAddr.ntop(socket.read(4))
        when 0x03 # DOMAINNAME
          length = socket.read(1).unpack("C").first
          destination = socket.read(length).unpack("A#{length}")
        when 0x04 # IP V6 address
          destination = IPAddr.ntop(socket.read(16))
        else
          raise "unsupported SOCKS5 address type"
        end

        port = socket.read(2).unpack("n").first
      end

      def check_version(version, should_be = VERSION)
        raise "mismatched SOCKS version" unless version == should_be
      end

    private
      def authentication_methods
        methods = []
        methods << 0x00         # NO AUTHENTICATION REQUIRED
        methods << 0x02 if user # USERNAME/PASSWORD
        methods
      end
  end

  SOCKS5Proxy = SOCKSProxy
end
