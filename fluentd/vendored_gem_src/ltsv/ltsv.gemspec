# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ltsv'

Gem::Specification.new do |gem|
  gem.name          = "ltsv"
  gem.version       = LTSV::VERSION
  gem.authors       = ["condor"]
  gem.email         = ["condor1226@gmail.com"]
  gem.description   = %q{A Parser / Dumper for LTSV}
  gem.summary       = %q{A Parser / Dumper for LTSV}
  gem.homepage      = "https://github.com/condor/ltsv"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency 'rspec'
end
