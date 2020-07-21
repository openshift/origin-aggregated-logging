require "socket"
require "uri"
require "uri/socks"

module Proxifier
  class Proxy
    class << self
      def proxify?(host, no_proxy = nil)
        return true unless no_proxy

        dont_proxy = no_proxy.split(",")
        dont_proxy.none? { |h| host =~ /#{h}\Z/ }
      end
    end

    attr_reader :url, :options

    def initialize(url, options = {})
      url = URI.parse(uri) unless url.is_a?(URI::Generic)
      @url, @options = url, options
    end

    def open(host, port, local_host = nil, local_port = nil)
      return TCPSocket.new(host, port, local_host, local_port) unless proxify?(host)

      socket = TCPSocket.new(self.host, self.port, local_host, local_port)

      begin
        proxify(socket, host, port)
      rescue
        socket.close
        raise
      end

      socket
    end

    def proxify?(host)
      self.class.proxify?(host, options[:no_proxy])
    end

    def proxify(socket, host, port)
      do_proxify(socket, host, port)
    end

    %w(host port user password query version).each do |attr|
      class_eval "def #{attr}; url.#{attr} end"
    end

    def query_options
      @query_options ||= query ? Hash[query.split("&").map { |q| q.split("=") }] : {}
    end

    %w(no_proxy).each do |option|
      class_eval "def #{option}; options[:#{option}] end"
    end

    protected
      def do_proxify(socket, host, port)
        raise NotImplementedError, "#{self} must implement do_proxify"
      end
  end
end
