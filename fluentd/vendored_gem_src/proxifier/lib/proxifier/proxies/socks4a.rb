require "proxifier/proxies/socks"

module Proxifier
  class SOCKS4AProxy < SOCKSProxy
    def do_proxify(*)
      raise NotImplementedError, "SOCKS4A is not yet implemented"
    end
  end
end
