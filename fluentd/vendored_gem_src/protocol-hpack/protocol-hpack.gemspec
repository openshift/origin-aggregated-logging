# -*- encoding: utf-8 -*-
# stub: protocol-hpack 1.4.2 ruby lib

Gem::Specification.new do |s|
  s.name = "protocol-hpack".freeze
  s.version = "1.4.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Samuel Williams".freeze]
  s.date = "2020-02-01"
  s.email = ["samuel.williams@oriontransfer.co.nz".freeze]
  s.files = [".editorconfig".freeze, ".gitignore".freeze, ".gitmodules".freeze, ".rspec".freeze, ".travis.yml".freeze, "Gemfile".freeze, "README.md".freeze, "Rakefile".freeze, "http-hpack.gemspec".freeze, "lib/protocol/hpack.rb".freeze, "lib/protocol/hpack/compressor.rb".freeze, "lib/protocol/hpack/context.rb".freeze, "lib/protocol/hpack/decompressor.rb".freeze, "lib/protocol/hpack/error.rb".freeze, "lib/protocol/hpack/huffman.rb".freeze, "lib/protocol/hpack/huffman/machine.rb".freeze, "lib/protocol/hpack/version.rb".freeze, "tasks/huffman.rake".freeze, "tasks/huffman.rb".freeze]
  s.homepage = "https://github.com/socketry/http-hpack".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.9".freeze
  s.summary = "A compresssor and decompressor for HTTP 2.0 HPACK.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<covered>.freeze, [">= 0"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
    else
      s.add_dependency(%q<covered>.freeze, [">= 0"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<covered>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
  end
end

