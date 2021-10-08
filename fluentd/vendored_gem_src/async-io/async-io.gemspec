# -*- encoding: utf-8 -*-
# stub: async-io 1.32.2 ruby lib

Gem::Specification.new do |s|
  s.name = "async-io".freeze
  s.version = "1.32.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Samuel Williams".freeze]
  s.date = "2021-07-16"
  s.files = ["lib/async/io.rb".freeze, "lib/async/io/address.rb".freeze, "lib/async/io/address_endpoint.rb".freeze, "lib/async/io/binary_string.rb".freeze, "lib/async/io/buffer.rb".freeze, "lib/async/io/endpoint.rb".freeze, "lib/async/io/endpoint/each.rb".freeze, "lib/async/io/generic.rb".freeze, "lib/async/io/host_endpoint.rb".freeze, "lib/async/io/notification.rb".freeze, "lib/async/io/peer.rb".freeze, "lib/async/io/protocol/generic.rb".freeze, "lib/async/io/protocol/line.rb".freeze, "lib/async/io/server.rb".freeze, "lib/async/io/shared_endpoint.rb".freeze, "lib/async/io/socket.rb".freeze, "lib/async/io/socket_endpoint.rb".freeze, "lib/async/io/ssl_endpoint.rb".freeze, "lib/async/io/ssl_socket.rb".freeze, "lib/async/io/standard.rb".freeze, "lib/async/io/stream.rb".freeze, "lib/async/io/tcp_socket.rb".freeze, "lib/async/io/threads.rb".freeze, "lib/async/io/trap.rb".freeze, "lib/async/io/udp_socket.rb".freeze, "lib/async/io/unix_endpoint.rb".freeze, "lib/async/io/unix_socket.rb".freeze, "lib/async/io/version.rb".freeze]
  s.homepage = "https://github.com/socketry/async-io".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.0.9".freeze
  s.summary = "Provides support for asynchonous TCP, UDP, UNIX and SSL sockets.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<async>.freeze, [">= 0"])
      s.add_development_dependency(%q<async-container>.freeze, ["~> 0.15"])
      s.add_development_dependency(%q<async-rspec>.freeze, ["~> 1.10"])
      s.add_development_dependency(%q<covered>.freeze, [">= 0"])
      s.add_development_dependency(%q<rack-test>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.6"])
    else
      s.add_dependency(%q<async>.freeze, [">= 0"])
      s.add_dependency(%q<async-container>.freeze, ["~> 0.15"])
      s.add_dependency(%q<async-rspec>.freeze, ["~> 1.10"])
      s.add_dependency(%q<covered>.freeze, [">= 0"])
      s.add_dependency(%q<rack-test>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.6"])
    end
  else
    s.add_dependency(%q<async>.freeze, [">= 0"])
    s.add_dependency(%q<async-container>.freeze, ["~> 0.15"])
    s.add_dependency(%q<async-rspec>.freeze, ["~> 1.10"])
    s.add_dependency(%q<covered>.freeze, [">= 0"])
    s.add_dependency(%q<rack-test>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.6"])
  end
end

