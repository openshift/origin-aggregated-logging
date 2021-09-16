
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)


# can override for testing
FLUENTD_VERSION = ENV['FLUENTD_VERSION'] || "0.12.0"

Gem::Specification.new do |gem|
  gem.name          = "formatter-single-json-value"
  gem.version       = "0.0.1"
  gem.authors       = ["Vimal Kumar"]
  gem.email         = ["vimal78@gmail.com"]

  gem.summary       = %q{Formatter to extract a single value as string of json string}
  gem.description   = %q{Formatter to extract a single value as string of json string}
  gem.license       = "MIT"

  gem.required_ruby_version = '>= 2.0.0'

  gem.add_runtime_dependency "fluentd", "~> #{FLUENTD_VERSION}"

  gem.add_development_dependency "bundler"
  gem.add_development_dependency("fluentd", "~> #{FLUENTD_VERSION}")
  gem.add_development_dependency("rake", ["~> 11.0"])
  gem.add_development_dependency("rr", ["~> 1.0"])
  gem.add_development_dependency("test-unit", ["~> 3.2"])
  gem.add_development_dependency("test-unit-rr", ["~> 1.0"])


end

