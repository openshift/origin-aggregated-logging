# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-viaq_data_model"
  gem.version       = "0.0.23"
  gem.authors       = ["OpenShift Logging Team"]
  gem.email         = ["aoslogging@redhat.com"]
  gem.description   = %q{Filter plugin to ensure data is in the ViaQ common data model}
  gem.summary       = %q{Filter plugin to ensure data is in the ViaQ common data model}
  gem.homepage      = "https://github.com/ViaQ/fluent-plugin-viaq_data_model"
  gem.license       = "Apache-2.0"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>= 2.0.0'
  gem.add_runtime_dependency("fluentd",  ">= 1.14.0")

  gem.add_development_dependency "bundler"
  gem.add_development_dependency("rake", ["~> 11.0"])
  gem.add_development_dependency("rr", ["~> 1.0"])
  gem.add_development_dependency("test-unit", ["~> 3.2"])
  gem.add_development_dependency("test-unit-rr", ["~> 1.0"])
end
