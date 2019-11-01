# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "fluent-plugin-gelf-hs"
  s.version   = ENV.key?('RUBYGEM_VERSION') ? ENV['RUBYGEM_VERSION'] : '1.0.3'
  s.authors     = ["Alex Yamauchi", "Eric Searcy"]
  s.email       = ["oss@hotschedules.com"]
  s.homepage    = "https://github.com/bodhi-space/fluent-plugin-gelf-hs"
  s.summary     = "Buffered fluentd output plugin to GELF (Graylog2)"
  # When building gems, there is always a stupid warning message thrown
  # if the summary and description are identical.
  s.description = s.summary + '.'
  s.licenses    = ["Apache-2.0"]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "test-unit"
  s.add_development_dependency "rake"
  s.add_runtime_dependency "fluentd"
  s.add_runtime_dependency "gelf", ">= 2.0.0"

end
