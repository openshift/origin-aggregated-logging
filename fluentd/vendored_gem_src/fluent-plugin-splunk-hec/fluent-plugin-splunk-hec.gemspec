# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'fluent-plugin-splunk-hec'
  spec.version       = File.read('VERSION')
  spec.authors       = ['Splunk Inc.']
  spec.email         = ['DataEdge@splunk.com']

  spec.summary       = 'Fluentd plugin for Splunk HEC.'
  spec.description   = 'A fluentd output plugin created by Splunk
  that writes events to splunk indexers over HTTP Event Collector API.'
  spec.homepage      = 'https://github.com/splunk/fluent-plugin-splunk-hec'
  spec.license       = 'Apache-2.0'

  # Prevent pushing this gem to RubyGems.org.
  # To allow pushes either set the 'allowed_push_host' to allow
  # pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.require_paths = ['lib']
  spec.test_files    = Dir.glob('test/**/**.rb')
  spec.files         = %w[
    CODE_OF_CONDUCT.md README.md LICENSE
    fluent-plugin-splunk-hec.gemspec
    Gemfile Gemfile.lock
    Rakefile VERSION
  ] + Dir.glob('lib/**/**').reject(&File.method(:directory?))

  spec.required_ruby_version = '>= 2.3.0'

  spec.add_runtime_dependency 'fluent-plugin-kubernetes_metadata_filter', '~> 2.4'
  spec.add_runtime_dependency 'fluentd', '>= 1.4'
  spec.add_runtime_dependency 'multi_json', '~> 1.13'
  spec.add_runtime_dependency 'net-http-persistent', '~> 3.1'
  spec.add_runtime_dependency 'openid_connect', '~> 1.1.8'
  spec.add_runtime_dependency 'prometheus-client', '< 0.10.0'
  spec.add_runtime_dependency 'activesupport', '~> 5.2'
  spec.add_runtime_dependency 'http_parser.rb', '= 0.5.3'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 12.0'
  # required by fluent/test.rb
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rubocop', '~> 0.63.1'
  spec.add_development_dependency 'simplecov', '~> 0.16.1'
  spec.add_development_dependency 'test-unit', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 3.5.0'
end
