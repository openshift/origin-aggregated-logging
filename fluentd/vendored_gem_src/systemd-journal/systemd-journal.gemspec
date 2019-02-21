# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'systemd/journal/version'

Gem::Specification.new do |gem|
  gem.name          = 'systemd-journal'
  gem.version       = Systemd::Journal::VERSION
  gem.license       = 'MIT'
  gem.authors       = ['John Ledbetter', 'Daniel Mack']
  gem.email         = ['john@throttle.io']
  gem.description   = 'Provides the ability to navigate and read entries from the systemd journal in ruby, as well as write events to the journal.'
  gem.summary       = 'Ruby bindings to libsystemd-journal'
  gem.homepage      = 'https://github.com/ledbettj/systemd-journal'

  gem.cert_chain    = Dir['certs/*']

  if $PROGRAM_NAME.end_with?('gem')
    gem.signing_key = ENV['GEM_SIGNING_KEY']
    raise ArgumentError, 'Please set GEM_SIGNING_KEY' if gem.signing_key.nil?
  end

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 1.9.3'

  gem.add_runtime_dependency 'ffi', '~> 1.9'

  gem.add_development_dependency 'rspec',     '~> 3.4'
  gem.add_development_dependency 'simplecov', '~> 0.9'
  gem.add_development_dependency 'rubocop',   '~> 0.26' unless ENV['RUBOCOP'] == 'false'
  gem.add_development_dependency 'rake',      '~> 10.3'
  gem.add_development_dependency 'yard',      '~> 0.9'
  gem.add_development_dependency 'pry',       '~> 0.10'
end
