# -*- encoding: utf-8 -*-
# stub: fluent-plugin-systemd 1.0.5 ruby lib

Gem::Specification.new do |s|
  s.name = "fluent-plugin-systemd".freeze
  s.version = "1.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ed Robinson".freeze]
  s.date = "2021-05-28"
  s.description = "This is a fluentd input plugin. It reads logs from the systemd journal.".freeze
  s.email = ["edward-robinson@cookpad.com".freeze]
  s.files = ["LICENCE".freeze, "README.md".freeze, "lib/fluent/plugin/filter_systemd_entry.rb".freeze, "lib/fluent/plugin/in_systemd.rb".freeze, "lib/fluent/plugin/systemd/entry_mutator.rb".freeze]
  s.homepage = "https://github.com/reevoo/fluent-plugin-systemd".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "3.0.9".freeze
  s.summary = "Input plugin to read from systemd journal.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["> 1.10"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<test-unit>.freeze, ["~> 3.4"])
      s.add_development_dependency(%q<rubocop>.freeze, ["= 1.13.0"])
      s.add_runtime_dependency(%q<fluentd>.freeze, [">= 0.14.11", "< 2"])
      s.add_runtime_dependency(%q<systemd-journal>.freeze, ["~> 1.4.2"])
    else
      s.add_dependency(%q<bundler>.freeze, ["> 1.10"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<test-unit>.freeze, ["~> 3.4"])
      s.add_dependency(%q<rubocop>.freeze, ["= 1.13.0"])
      s.add_dependency(%q<fluentd>.freeze, [">= 0.14.11", "< 2"])
      s.add_dependency(%q<systemd-journal>.freeze, ["~> 1.4.2"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["> 1.10"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit>.freeze, ["~> 3.4"])
    s.add_dependency(%q<rubocop>.freeze, ["= 1.13.0"])
    s.add_dependency(%q<fluentd>.freeze, [">= 0.14.11", "< 2"])
    s.add_dependency(%q<systemd-journal>.freeze, ["~> 1.4.2"])
  end
end

