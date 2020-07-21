require "socket"
require "proxifier"

module Proxifier
  class Proxy
    def open(host, port, local_host = nil, local_port = nil)
      return TCPSocket.new(host, port, local_host, local_port, :proxy => nil) unless proxify?(host)

      socket = TCPSocket.new(self.host, self.port, local_host, local_port, :proxy => nil)

      begin
        proxify(socket, host, port)
      rescue
        socket.close
        raise
      end

      socket
    end
  end

  module Proxify
    def self.included(klass)
      klass.class_eval do
        alias_method :initialize_without_proxy, :initialize
        alias_method :initialize, :initialize_with_proxy
      end
    end

    def initialize_with_proxy(host, port, options_or_local_host = {}, local_port = nil, options_if_local_host = {})
      if options_or_local_host.is_a?(Hash)
        local_host = nil
        options = options_or_local_host
      else
        local_host = options_or_local_host
        options = options_if_local_host
      end

      if options[:proxy] && (proxy = Proxifier::Proxy(options.delete(:proxy), options)) && proxy.proxify?(host)
        initialize_without_proxy(proxy.host, proxy.port, local_host, local_port)
        begin
          proxy.proxify(self, host, port)
        rescue
          close
          raise
        end
      else
        initialize_without_proxy(host, port, local_host, local_port)
      end
    end
  end

  module EnvironmentProxify
    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
        alias_method :initialize_without_environment_proxy, :initialize
        alias_method :initialize, :initialize_with_environment_proxy
      end
    end

    def initialize_with_environment_proxy(host, port, options_or_local_host = {}, local_port = nil, options_if_local_host = {})
      if options_or_local_host.is_a?(Hash)
        local_host = nil
        options = options_or_local_host
      else
        local_host = options_or_local_host
        options = options_if_local_host
      end

      options = { :proxy => environment_proxy, :no_proxy => environment_no_proxy }.merge(options)
      initialize_without_environment_proxy(host, port, local_host, local_port, options)
    end

    def environment_proxy
      self.class.environment_proxy
    end

    def environment_no_proxy
      self.class.environment_no_proxy
    end

    module ClassMethods
      def environment_proxy
        ENV["proxy"] || ENV["PROXY"] || specific_environment_proxy
      end

      def environment_no_proxy
        ENV["no_proxy"] || ENV["NO_PROXY"]
      end

      private
        def specific_environment_proxy
          %w(socks socks5 socks4a socks4 http).each do |type|
            if proxy = ENV["#{type}_proxy"] || ENV["#{type.upcase}_PROXY"]
              scheme = "#{type}://"

              proxy = proxy.dup
              proxy.insert(0, scheme) unless proxy.index(scheme) == 0
              return proxy
            end
          end

          nil
        end
    end
  end
end

class TCPSocket
  include Proxifier::Proxify
  include Proxifier::EnvironmentProxify
end
