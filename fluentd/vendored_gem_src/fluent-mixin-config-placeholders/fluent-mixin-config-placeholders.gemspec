# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name          = "fluent-mixin-config-placeholders"
  gem.version       = "0.4.0"
  gem.authors       = ["TAGOMORI Satoshi"]
  gem.email         = ["tagomoris@gmail.com"]
  gem.description   = %q{to add various placeholders for plugin configurations}
  gem.summary       = %q{Configuration syntax extension mixin for fluentd plugin}
  gem.homepage      = "https://github.com/tagomoris/fluent-mixin-config-placeholders"
  gem.license       = "Apache-2.0"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "fluentd"
  gem.add_runtime_dependency "uuidtools", ">= 2.1.5"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "test-unit"
end
