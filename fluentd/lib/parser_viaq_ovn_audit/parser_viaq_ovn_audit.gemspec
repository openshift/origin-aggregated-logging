# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# can override for testing
FLUENTD_VERSION = ENV['FLUENTD_VERSION'] || "1.12.0"

Gem::Specification.new do |gem|
  gem.name          = "parser_viaq_ovn_audit"
  gem.version       = "0.0.1"
  gem.authors       = ["Ajay Gupta"]
  gem.summary       = %q{Parser plugin to read ovn audit records}

  gem.required_ruby_version = '>= 2.0.0'

  gem.add_runtime_dependency "fluentd", "~> #{FLUENTD_VERSION}"

  gem.add_development_dependency "bundler"
  gem.add_development_dependency("fluentd", "~> #{FLUENTD_VERSION}")
  gem.add_development_dependency("rake", ["~> 13.0"])
  gem.add_development_dependency("rr", ["~> 3.0"])
  gem.add_development_dependency("test-unit", ["~> 3.2"])
  gem.add_development_dependency("test-unit-rr", ["~> 1.0"])
end
