# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-concat"
  spec.version       = "2.5.0"
  spec.authors       = ["Kenji Okimoto"]
  spec.email         = ["okimoto@clear-code.com"]

  spec.summary       = "Fluentd Filter plugin to concat multiple event messages"
  spec.description   = "Fluentd Filter plugin to concat multiple event messages"
  spec.homepage      = "https://github.com/fluent-plugins-nursery/fluent-plugin-concat"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject {|f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "fluentd", ">= 0.14.0", "< 2"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "test-unit", ">= 3.1.0"
  spec.add_development_dependency "test-unit-rr"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "webrick"
end
