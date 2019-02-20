# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "fluentd-okd-config-generator"
  gem.version       = "0.0.1"
  gem.authors       = ["aos-logging@redhat.com"]
  gem.summary       = %q{OKD config generator for use with OKD ClusterLogging}
  gem.executables << gem.name
  gem.files         = Dir.glob("{bin,lib}/**/*")
  gem.require_path = 'lib'

  gem.required_ruby_version = '>= 2.0.0'

end
