# -*- encoding: utf-8 -*-
# stub: protocol-http2 0.14.2 ruby lib

Gem::Specification.new do |s|
  s.name = "protocol-http2".freeze
  s.version = "0.14.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Samuel Williams".freeze]
  s.date = "2021-01-25"
  s.files = ["lib/protocol/http2.rb".freeze, "lib/protocol/http2/client.rb".freeze, "lib/protocol/http2/connection.rb".freeze, "lib/protocol/http2/continuation_frame.rb".freeze, "lib/protocol/http2/data_frame.rb".freeze, "lib/protocol/http2/dependency.rb".freeze, "lib/protocol/http2/error.rb".freeze, "lib/protocol/http2/flow_controlled.rb".freeze, "lib/protocol/http2/frame.rb".freeze, "lib/protocol/http2/framer.rb".freeze, "lib/protocol/http2/goaway_frame.rb".freeze, "lib/protocol/http2/headers_frame.rb".freeze, "lib/protocol/http2/padded.rb".freeze, "lib/protocol/http2/ping_frame.rb".freeze, "lib/protocol/http2/priority_frame.rb".freeze, "lib/protocol/http2/push_promise_frame.rb".freeze, "lib/protocol/http2/reset_stream_frame.rb".freeze, "lib/protocol/http2/server.rb".freeze, "lib/protocol/http2/settings_frame.rb".freeze, "lib/protocol/http2/stream.rb".freeze, "lib/protocol/http2/version.rb".freeze, "lib/protocol/http2/window_update_frame.rb".freeze]
  s.homepage = "https://github.com/socketry/protocol-http2".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.0.9".freeze
  s.summary = "A low level implementation of the HTTP/2 protocol.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<protocol-hpack>.freeze, ["~> 1.4"])
      s.add_runtime_dependency(%q<protocol-http>.freeze, ["~> 0.18"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<covered>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
    else
      s.add_dependency(%q<protocol-hpack>.freeze, ["~> 1.4"])
      s.add_dependency(%q<protocol-http>.freeze, ["~> 0.18"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<covered>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<protocol-hpack>.freeze, ["~> 1.4"])
    s.add_dependency(%q<protocol-http>.freeze, ["~> 0.18"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<covered>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
  end
end

