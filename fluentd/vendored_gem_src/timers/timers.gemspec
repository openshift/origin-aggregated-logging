# -*- encoding: utf-8 -*-
# stub: timers 4.3.3 ruby lib

Gem::Specification.new do |s|
  s.name = "timers".freeze
  s.version = "4.3.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Samuel Williams".freeze, "Tony Arcieri".freeze]
  s.date = "2021-02-13"
  s.files = ["lib/timers.rb".freeze, "lib/timers/events.rb".freeze, "lib/timers/group.rb".freeze, "lib/timers/interval.rb".freeze, "lib/timers/priority_heap.rb".freeze, "lib/timers/timer.rb".freeze, "lib/timers/version.rb".freeze, "lib/timers/wait.rb".freeze]
  s.homepage = "https://github.com/socketry/timers".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.9".freeze
  s.summary = "Pure Ruby one-shot and periodic timers.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<covered>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
    else
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<covered>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<covered>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
  end
end

