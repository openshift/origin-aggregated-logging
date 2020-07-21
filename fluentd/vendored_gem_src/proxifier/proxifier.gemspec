# -*- encoding: utf-8 -*-
# stub: proxifier 1.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "proxifier".freeze
  s.version = "1.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Samuel Kadolph".freeze]
  s.date = "2012-03-06"
  s.description = "Proxifier adds support for HTTP or SOCKS proxies and lets you force TCPSocket to use proxies.".freeze
  s.email = ["samuel@kadolph.com".freeze]
  s.executables = ["pirb".freeze, "pruby".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze, "bin/pirb".freeze, "bin/pruby".freeze, "lib/proxifier.rb".freeze, "lib/proxifier/env.rb".freeze, "lib/proxifier/errors.rb".freeze, "lib/proxifier/proxies/http.rb".freeze, "lib/proxifier/proxies/socks.rb".freeze, "lib/proxifier/proxies/socks4.rb".freeze, "lib/proxifier/proxies/socks4a.rb".freeze, "lib/proxifier/proxy.rb".freeze, "lib/proxifier/version.rb".freeze, "lib/uri/socks.rb".freeze]
  s.homepage = "https://github.com/samuelkadolph/ruby-proxifier".freeze
  s.rubygems_version = "3.0.8".freeze
  s.summary = "Proxifier is a gem to force ruby to use a proxy.".freeze
end

