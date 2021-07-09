Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-collected"
  spec.version       = "1.0.0"
  spec.authors       = ["RedHat"]
  spec.email         = ["team-logging@redhat.com"]
  spec.homepage      = "https://github.com/openshift/origin-aggregated-logging/tree/master/fluentd/lib/fluent-plugin-collected"
  spec.summary       = %q{A fluent plugin that collects metrics on total bytes collected by fluentd.}
  spec.description   = %q{A fluent plugin that collects metrics on total bytes collected by fluentd and exposes that for Prometheus.}
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "fluentd", ">= 0.14.20", "< 2"
  spec.add_dependency "prometheus-client", "< 0.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "test-unit", "~> 3.0"
  spec.add_development_dependency "test-unit-rr", "~> 1.0"
  spec.add_development_dependency "fluent-plugin-prometheus", "~> 1.8.5"


end
