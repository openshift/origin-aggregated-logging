require "uri/generic"

module URI
  class SOCKS < Generic
    DEFAULT_PORT = 1080
    COMPONENT = [:scheme, :userinfo, :host, :port, :query].freeze
  end
  @@schemes["SOCKS"] = SOCKS
  @@schemes["SOCKS5"] = SOCKS

  class SOCKS4 < SOCKS
  end
  @@schemes["SOCKS4"] = SOCKS4

  class SOCKS4A < SOCKS
  end
  @@schemes["SOCKS4A"] = SOCKS4A
end
