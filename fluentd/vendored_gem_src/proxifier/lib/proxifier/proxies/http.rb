require "net/http"
require "proxifier/proxy"

module Proxifier
  class HTTPProxy < Proxy
    def do_proxify(socket, host, port)
      return if query_options["tunnel"] == "false"

      socket << "CONNECT #{host}:#{port} HTTP/1.1\r\n"
      socket << "Host: #{host}:#{port}\r\n"
      socket << "Proxy-Authorization: Basic #{["#{user}:#{password}"].pack("m").chomp}\r\n" if user
      socket << "\r\n"

      buffer = Net::BufferedIO.new(socket)
      response = Net::HTTPResponse.read_new(buffer)
      response.error! unless response.is_a?(Net::HTTPOK)
    end
  end
end
