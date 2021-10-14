lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name    = "fluent-plugin-label-router"
  spec.version = "0.2.10"
  spec.authors = ["Banzai Cloud"]
  spec.email   = ["info@banzaicloud.com"]

  spec.summary       = %q{Routing records based on Kubernetes labels.}
  spec.description   = %q{Label-Router helps routing log messages based on their labels and namespace tag in a Kubernetes environment.}
  spec.homepage      = "https://github.com/banzaicloud/fluent-plugin-label-router"
  spec.license       = "Apache-2.0"

  test_files, files  = `git ls-files -z`.split("\x0").partition do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.files         = files
  spec.executables   = files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = test_files
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "test-unit", "~> 3.0"
  spec.add_dependency "prometheus-client", ">= 2.1.0"
  spec.add_runtime_dependency "fluentd", [">= 0.14.10", "< 2"]
end
