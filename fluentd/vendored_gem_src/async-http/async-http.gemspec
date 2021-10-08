# -*- encoding: utf-8 -*-
# stub: async-http 0.56.5 ruby lib

Gem::Specification.new do |s|
  s.name = "async-http".freeze
  s.version = "0.56.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Samuel Williams".freeze]
  s.date = "2021-07-16"
  s.files = ["bake/async/http.rb".freeze, "bake/async/http/h2spec.rb".freeze, "lib/async/http.rb".freeze, "lib/async/http/body.rb".freeze, "lib/async/http/body/delayed.rb".freeze, "lib/async/http/body/hijack.rb".freeze, "lib/async/http/body/pipe.rb".freeze, "lib/async/http/body/slowloris.rb".freeze, "lib/async/http/body/stream.rb".freeze, "lib/async/http/body/writable.rb".freeze, "lib/async/http/client.rb".freeze, "lib/async/http/endpoint.rb".freeze, "lib/async/http/internet.rb".freeze, "lib/async/http/internet/instance.rb".freeze, "lib/async/http/protocol.rb".freeze, "lib/async/http/protocol/http1.rb".freeze, "lib/async/http/protocol/http1/client.rb".freeze, "lib/async/http/protocol/http1/connection.rb".freeze, "lib/async/http/protocol/http1/request.rb".freeze, "lib/async/http/protocol/http1/response.rb".freeze, "lib/async/http/protocol/http1/server.rb".freeze, "lib/async/http/protocol/http10.rb".freeze, "lib/async/http/protocol/http11.rb".freeze, "lib/async/http/protocol/http2.rb".freeze, "lib/async/http/protocol/http2/client.rb".freeze, "lib/async/http/protocol/http2/connection.rb".freeze, "lib/async/http/protocol/http2/input.rb".freeze, "lib/async/http/protocol/http2/output.rb".freeze, "lib/async/http/protocol/http2/request.rb".freeze, "lib/async/http/protocol/http2/response.rb".freeze, "lib/async/http/protocol/http2/server.rb".freeze, "lib/async/http/protocol/http2/stream.rb".freeze, "lib/async/http/protocol/https.rb".freeze, "lib/async/http/protocol/request.rb".freeze, "lib/async/http/protocol/response.rb".freeze, "lib/async/http/proxy.rb".freeze, "lib/async/http/reference.rb".freeze, "lib/async/http/relative_location.rb".freeze, "lib/async/http/server.rb".freeze, "lib/async/http/statistics.rb".freeze, "lib/async/http/version.rb".freeze]
  s.homepage = "https://github.com/socketry/async-http".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.9".freeze
  s.summary = "A HTTP client and server library.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<async>.freeze, [">= 1.25"])
      s.add_runtime_dependency(%q<async-io>.freeze, [">= 1.28"])
      s.add_runtime_dependency(%q<async-pool>.freeze, [">= 0.2"])
      s.add_runtime_dependency(%q<protocol-http>.freeze, ["~> 0.22.0"])
      s.add_runtime_dependency(%q<protocol-http1>.freeze, ["~> 0.14.0"])
      s.add_runtime_dependency(%q<protocol-http2>.freeze, ["~> 0.14.0"])
      s.add_development_dependency(%q<async-container>.freeze, ["~> 0.14"])
      s.add_development_dependency(%q<async-rspec>.freeze, ["~> 1.10"])
      s.add_development_dependency(%q<covered>.freeze, [">= 0"])
      s.add_development_dependency(%q<rack-test>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.6"])
      s.add_development_dependency(%q<localhost>.freeze, [">= 0"])
    else
      s.add_dependency(%q<async>.freeze, [">= 1.25"])
      s.add_dependency(%q<async-io>.freeze, [">= 1.28"])
      s.add_dependency(%q<async-pool>.freeze, [">= 0.2"])
      s.add_dependency(%q<protocol-http>.freeze, ["~> 0.22.0"])
      s.add_dependency(%q<protocol-http1>.freeze, ["~> 0.14.0"])
      s.add_dependency(%q<protocol-http2>.freeze, ["~> 0.14.0"])
      s.add_dependency(%q<async-container>.freeze, ["~> 0.14"])
      s.add_dependency(%q<async-rspec>.freeze, ["~> 1.10"])
      s.add_dependency(%q<covered>.freeze, [">= 0"])
      s.add_dependency(%q<rack-test>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.6"])
      s.add_dependency(%q<localhost>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<async>.freeze, [">= 1.25"])
    s.add_dependency(%q<async-io>.freeze, [">= 1.28"])
    s.add_dependency(%q<async-pool>.freeze, [">= 0.2"])
    s.add_dependency(%q<protocol-http>.freeze, ["~> 0.22.0"])
    s.add_dependency(%q<protocol-http1>.freeze, ["~> 0.14.0"])
    s.add_dependency(%q<protocol-http2>.freeze, ["~> 0.14.0"])
    s.add_dependency(%q<async-container>.freeze, ["~> 0.14"])
    s.add_dependency(%q<async-rspec>.freeze, ["~> 1.10"])
    s.add_dependency(%q<covered>.freeze, [">= 0"])
    s.add_dependency(%q<rack-test>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.6"])
    s.add_dependency(%q<localhost>.freeze, [">= 0"])
  end
end

