require "resolve/hostname/version"

require 'ipaddr'
require 'socket'
require 'resolv'

module Resolve
  class Hostname
    class NotFoundError < StandardError; end
  end
end

module Resolve
  class Hostname
    attr_accessor :ttl, :resolver_ttl, :resolver_expires
    attr_reader :cache # for testing

    DEFAULT_EXPIRATION_SECONDS = 60
    DEFAULT_RESOLVER_TTL = 1800 # for rereading of /etc/resolve.conf

    DEFAULT_ENABLE_SYSTEM_RESOLVER = false

    DEFAULT_PRIMARY_ADDRESS_VERSION = :ipv4
    DEFAULT_PERMIT_SECONDARY_ADDRESS_VERSION = true
    ADDRESS_VERSIONS = [:ipv4, :ipv6]

    DEFAULT_RAISE_NOTFOUND = true

    #TODO: negative caching not implemented
    # DEFAULT_NEGATIVE_CACHE = false # disabled

    #TODO: DNS RoundRobin with resolv
    # DEFAULT_SUPPORTS_DNS_RR = false

    def initialize(opts={})
      @primary_ip_version = opts[:version] || DEFAULT_PRIMARY_ADDRESS_VERSION
      unless ADDRESS_VERSIONS.include? @primary_ip_version
        raise ArgumentError, "unknown version of ip address: #{opts[:version]}"
      end

      @ttl = opts[:ttl] || DEFAULT_EXPIRATION_SECONDS
      @resolver_ttl = opts[:resolver_ttl] || DEFAULT_RESOLVER_TTL

      @system_resolver_enabled = opts.fetch(:system_resolver, DEFAULT_ENABLE_SYSTEM_RESOLVER)
      @permit_secondary_address_version = opts.fetch(:permit_other_version, DEFAULT_PERMIT_SECONDARY_ADDRESS_VERSION)
      @raise_notfound = opts.fetch(:raise_notfound, DEFAULT_RAISE_NOTFOUND)

      @cache = {}
      @mutex = Mutex.new

      @resolver = nil
      @resolver_expires = nil

      @invalid_address_error = if IPAddr.const_defined?('InvalidAddressError')
                                 IPAddr::InvalidAddressError
                               else
                                 ArgumentError
                               end
    end

    def getaddress(name)
      unless @cache[name]
        @mutex.synchronize do
          @cache[name] ||= CachedValue.new(@ttl)
        end
      end
      @cache[name].get_or_refresh{ resolve(name) }
    end

    def primary_ip_version
      @primary_ip_version
    end

    def secondary_ip_version
      @primary_ip_version == :ipv4 ? :ipv6 : :ipv4
    end

    def primary_version_address?(str)
      if @primary_ip_version == :ipv4
        IPAddr.new(str).ipv4?
      else
        IPAddr.new(str).ipv6?
      end
    end

    def resolve(name)
      secondary = nil

      is_address = false
      begin
        IPAddr.new(name)
        is_address = true
      rescue @invalid_address_error
        # ignore
      end
      return name if is_address

      if @system_resolver_enabled
        addr = resolve_builtin(name)
        if addr
          return addr if primary_version_address?(addr)
          secondary = addr
        end
      end

      addr = resolve_resolv(name, primary_ip_version)
      if addr
        return addr if primary_version_address?(addr)
        secondary ||= addr
      end

      if secondary.nil? && @permit_secondary_address_version
        secondary = resolve_resolv(name, secondary_ip_version)
      end

      addr = resolve_magic(name)
      if addr
        return addr if primary_version_address?(addr)
        secondary ||= addr
      end

      return secondary if secondary && @permit_secondary_address_version

      raise NotFoundError, "cannot resolve hostname #{name}" if @raise_notfound

      nil
    end

    def resolv_instance
      return @resolver if @resolver && @resolver_expires >= Time.now

      @resolver_expires = Time.now + @resolver_ttl
      @resolver = Resolv::DNS.new

      @resolver
    end

    def resolve_resolv(name, version)
      t = case version
          when :ipv4
            Resolv::DNS::Resource::IN::A
          when :ipv6
            Resolv::DNS::Resource::IN::AAAA
          else
            raise ArgumentError, "invalid ip address version:#{version}"
          end
      begin
        resolv_instance.getresource(name, t).address.to_s
      rescue Resolv::ResolvError => e
        raise unless e.message.start_with?('DNS result has no information for')
        nil
      end
    end

    def resolve_builtin(name)
      begin
        IPSocket.getaddress(name)
      rescue SocketError => e
        raise unless e.message.start_with?('getaddrinfo: nodename nor servname provided, or not known')
        nil
      end
    end

    def resolve_magic(name)
      if name =~ /^localhost$/i
        return @primary_ip_version == :ipv4 ? '127.0.0.1' : '::1'
      end
      nil
    end

    class CachedValue
      attr_accessor :value, :expires, :mutex

      #TODO: negative cache
      def initialize(ttl)
        @value = nil
        @ttl = ttl
        @expires = Time.now + ttl
        @mutex = Mutex.new
      end

      def get_or_refresh
        return @value if @value && @expires >= Time.now

        @mutex.synchronize do
          return @value if @value && @expires >= Time.now

          @value = yield
          # doesn't do negative cache (updating of @expires is passed when something raised above)
          @expires = Time.now + @ttl
        end

        @value
      end
    end
  end
end
