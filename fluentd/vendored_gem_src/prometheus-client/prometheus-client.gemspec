# -*- encoding: utf-8 -*-
# stub: prometheus-client 0.9.0 ruby lib

Gem::Specification.new do |s|
  s.name = "prometheus-client".freeze
  s.version = "0.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tobias Schmidt".freeze]
  s.date = "2019-01-25"
  s.email = ["ts@soundcloud.com".freeze]
  s.files = ["README.md".freeze, "lib/prometheus.rb".freeze, "lib/prometheus/client.rb".freeze, "lib/prometheus/client/counter.rb".freeze, "lib/prometheus/client/formats/text.rb".freeze, "lib/prometheus/client/gauge.rb".freeze, "lib/prometheus/client/histogram.rb".freeze, "lib/prometheus/client/label_set_validator.rb".freeze, "lib/prometheus/client/metric.rb".freeze, "lib/prometheus/client/push.rb".freeze, "lib/prometheus/client/registry.rb".freeze, "lib/prometheus/client/summary.rb".freeze, "lib/prometheus/client/version.rb".freeze, "lib/prometheus/middleware/collector.rb".freeze, "lib/prometheus/middleware/exporter.rb".freeze]
  s.homepage = "https://github.com/prometheus/client_ruby".freeze
  s.licenses = ["Apache 2.0".freeze]
  s.rubygems_version = "2.6.12".freeze
  s.summary = "A suite of instrumentation metric primitivesthat can be exposed through a web services interface.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<quantile>.freeze, ["~> 0.2.1"])
    else
      s.add_dependency(%q<quantile>.freeze, ["~> 0.2.1"])
    end
  else
    s.add_dependency(%q<quantile>.freeze, ["~> 0.2.1"])
  end
end

