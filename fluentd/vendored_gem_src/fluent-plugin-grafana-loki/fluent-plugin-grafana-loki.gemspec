# -*- encoding: utf-8 -*-
# stub: fluent-plugin-grafana-loki 1.2.12 ruby lib

Gem::Specification.new do |s|
  s.name = "fluent-plugin-grafana-loki".freeze
  s.version = "1.2.12"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["woodsaj".freeze, "briangann".freeze, "cyriltovena".freeze]
  s.date = "2020-05-15"
  s.description = "Output plugin to ship logs to a Grafana Loki server".freeze
  s.email = ["awoods@grafana.com".freeze, "brian@grafana.com".freeze, "cyril.tovena@grafana.com".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze, "bin/console".freeze, "bin/setup".freeze, "lib/fluent/plugin/out_loki.rb".freeze]
  s.homepage = "https://github.com/grafana/loki/".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Output plugin to ship logs to a Grafana Loki server".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 12.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_runtime_dependency(%q<fluentd>.freeze, [">= 1.9.0", "< 2"])
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, ["~> 12.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<fluentd>.freeze, [">= 1.9.0", "< 2"])
  end
end

