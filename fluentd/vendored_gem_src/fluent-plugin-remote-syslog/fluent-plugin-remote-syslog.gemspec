# encoding: utf-8
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "fluent-plugin-remote-syslog"
  gem.description = "Output plugin for streaming logs out to a remote syslog"
  gem.homepage    = "https://github.com/docebo/fluent-plugin-remote-syslog"
  gem.summary     = gem.description
  gem.version     = "1.1"
  gem.authors     = ["Andrea Spoldi"]
  gem.email       = "devops@docebo.com"
  gem.has_rdoc    = false
  gem.license     = 'MIT'
  gem.files       = `git ls-files`.split("\n")
  gem.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_dependency "fluentd"
  gem.add_dependency "fluent-mixin-config-placeholders"
  gem.add_dependency "syslog_protocol"
  gem.add_development_dependency "rake", ">= 0.9.2"
end
