# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fluent/plugin/cloudwatch/logs/version'

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-cloudwatch-logs"
  spec.version       = Fluent::Plugin::Cloudwatch::Logs::VERSION
  spec.authors       = ["Ryota Arai"]
  spec.email         = ["ryota.arai@gmail.com"]
  spec.summary       = %q{CloudWatch Logs Plugin for Fluentd}
  spec.homepage      = "https://github.com/fluent-plugins-nursery/fluent-plugin-cloudwatch-logs"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'fluentd', '>= 1.8.0'
  spec.add_dependency 'aws-sdk-cloudwatchlogs', '~> 1.0'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "test-unit-rr"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "nokogiri"
end
