# -*- encoding: utf-8 -*-
# stub: protocol-http 0.22.5 ruby lib

Gem::Specification.new do |s|
  s.name = "protocol-http".freeze
  s.version = "0.22.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Samuel Williams".freeze]
  s.date = "2021-07-15"
  s.files = ["lib/protocol/http.rb".freeze, "lib/protocol/http/accept_encoding.rb".freeze, "lib/protocol/http/body/buffered.rb".freeze, "lib/protocol/http/body/completable.rb".freeze, "lib/protocol/http/body/deflate.rb".freeze, "lib/protocol/http/body/digestable.rb".freeze, "lib/protocol/http/body/file.rb".freeze, "lib/protocol/http/body/head.rb".freeze, "lib/protocol/http/body/inflate.rb".freeze, "lib/protocol/http/body/readable.rb".freeze, "lib/protocol/http/body/reader.rb".freeze, "lib/protocol/http/body/rewindable.rb".freeze, "lib/protocol/http/body/stream.rb".freeze, "lib/protocol/http/body/wrapper.rb".freeze, "lib/protocol/http/content_encoding.rb".freeze, "lib/protocol/http/cookie.rb".freeze, "lib/protocol/http/error.rb".freeze, "lib/protocol/http/header/authorization.rb".freeze, "lib/protocol/http/header/cache_control.rb".freeze, "lib/protocol/http/header/connection.rb".freeze, "lib/protocol/http/header/cookie.rb".freeze, "lib/protocol/http/header/etag.rb".freeze, "lib/protocol/http/header/etags.rb".freeze, "lib/protocol/http/header/multiple.rb".freeze, "lib/protocol/http/header/split.rb".freeze, "lib/protocol/http/header/vary.rb".freeze, "lib/protocol/http/headers.rb".freeze, "lib/protocol/http/methods.rb".freeze, "lib/protocol/http/middleware.rb".freeze, "lib/protocol/http/middleware/builder.rb".freeze, "lib/protocol/http/reference.rb".freeze, "lib/protocol/http/request.rb".freeze, "lib/protocol/http/response.rb".freeze, "lib/protocol/http/url.rb".freeze, "lib/protocol/http/version.rb".freeze]
  s.homepage = "https://github.com/socketry/protocol-http".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.0.9".freeze
  s.summary = "Provides abstractions to handle HTTP protocols.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<covered>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    else
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<covered>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<covered>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
  end
end

