lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-config-regexp-type"
  spec.version       = "1.0.0"
  spec.authors       = ["Kenji Okimoto"]
  spec.email         = ["okimoto@clear-code.com"]

  spec.summary       = "The compatibility monkey patch to use regexp type "
  spec.description   = "The compatibility monkey patch to use regexp type "
  spec.homepage      = "https://github.com/okkez/fluent-config-regexp-type"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "> 10.0"
  spec.add_development_dependency "test-unit", "> 3"
  spec.add_runtime_dependency "fluentd", "> 1.0.0", "< 2"
end
