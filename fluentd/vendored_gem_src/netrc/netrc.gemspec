# -*- encoding: utf-8 -*-
# stub: netrc 0.11.0 ruby lib

Gem::Specification.new do |s|
  s.name = "netrc".freeze
  s.version = "0.11.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Keith Rarick".freeze, "geemus (Wesley Beary)".freeze]
  s.date = "2015-10-29"
  s.description = "This library can read and update netrc files, preserving formatting including comments and whitespace.".freeze
  s.email = "geemus@gmail.com".freeze
  s.files = ["LICENSE.md".freeze, "Readme.md".freeze, "changelog.txt".freeze, "data/default_only.netrc".freeze, "data/login.netrc".freeze, "data/newlineless.netrc".freeze, "data/password.netrc".freeze, "data/permissive.netrc".freeze, "data/sample.netrc".freeze, "data/sample_multi.netrc".freeze, "data/sample_multi_with_default.netrc".freeze, "data/sample_with_default.netrc".freeze, "lib/netrc.rb".freeze, "test/test_lex.rb".freeze, "test/test_netrc.rb".freeze, "test/test_parse.rb".freeze]
  s.homepage = "https://github.com/geemus/netrc".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.4".freeze
  s.summary = "Library to read and write netrc files.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
  else
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
  end
end

