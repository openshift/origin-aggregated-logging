require "uri"
require "uri/socks"

module Proxifier
  require "proxifier/version"

  autoload :HTTPProxy, "proxifier/proxies/http"
  autoload :SOCKSProxy, "proxifier/proxies/socks"
  autoload :SOCKS5Proxy, "proxifier/proxies/socks"
  autoload :SOCKS4Proxy, "proxifier/proxies/socks4"
  autoload :SOCKS4AProxy, "proxifier/proxies/socks4a"

  def self.Proxy(url, options = {})
    url = URI.parse(url)

    raise(ArgumentError, "proxy url has no scheme") unless url.scheme
    begin
      klass = const_get("#{url.scheme.upcase}Proxy")
    rescue NameError
      raise(ArgumentError, "unknown proxy scheme `#{url.scheme}'")
    end

    klass.new(url, options)
  end
end
