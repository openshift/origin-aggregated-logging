# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-remote_syslog"
  spec.version       = File.read("VERSION").strip
  spec.authors       = ["Richard Lee"]
  spec.email         = ["dlackty@gmail.com"]
  spec.summary       = %q{Fluentd output plugin for remote syslog}
  spec.description   = spec.description
  spec.homepage      = "https://github.com/dlackty/fluent-plugin-remote_syslog"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "test-unit-rr"

  spec.add_runtime_dependency "fluentd"
  spec.add_runtime_dependency "remote_syslog_sender", ">= 1.1.1"
end
