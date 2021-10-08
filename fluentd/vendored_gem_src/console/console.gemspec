# -*- encoding: utf-8 -*-
# stub: console 1.13.1 ruby lib

Gem::Specification.new do |s|
  s.name = "console".freeze
  s.version = "1.13.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Samuel Williams".freeze]
  s.date = "2021-06-11"
  s.files = ["bake/console.rb".freeze, "lib/console.rb".freeze, "lib/console/buffer.rb".freeze, "lib/console/capture.rb".freeze, "lib/console/clock.rb".freeze, "lib/console/event.rb".freeze, "lib/console/event/failure.rb".freeze, "lib/console/event/generic.rb".freeze, "lib/console/event/measure.rb".freeze, "lib/console/event/metric.rb".freeze, "lib/console/event/progress.rb".freeze, "lib/console/event/spawn.rb".freeze, "lib/console/filter.rb".freeze, "lib/console/logger.rb".freeze, "lib/console/measure.rb".freeze, "lib/console/output.rb".freeze, "lib/console/output/default.rb".freeze, "lib/console/output/json.rb".freeze, "lib/console/output/sensitive.rb".freeze, "lib/console/output/text.rb".freeze, "lib/console/output/xterm.rb".freeze, "lib/console/progress.rb".freeze, "lib/console/resolver.rb".freeze, "lib/console/serialized/logger.rb".freeze, "lib/console/split.rb".freeze, "lib/console/terminal.rb".freeze, "lib/console/terminal/logger.rb".freeze, "lib/console/terminal/text.rb".freeze, "lib/console/terminal/xterm.rb".freeze, "lib/console/version.rb".freeze]
  s.homepage = "https://github.com/socketry/console".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.0.9".freeze
  s.summary = "Beautiful logging for Ruby.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<fiber-local>.freeze, [">= 0"])
      s.add_development_dependency(%q<bake>.freeze, [">= 0"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<covered>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
    else
      s.add_dependency(%q<fiber-local>.freeze, [">= 0"])
      s.add_dependency(%q<bake>.freeze, [">= 0"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<covered>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<fiber-local>.freeze, [">= 0"])
    s.add_dependency(%q<bake>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<covered>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
  end
end

