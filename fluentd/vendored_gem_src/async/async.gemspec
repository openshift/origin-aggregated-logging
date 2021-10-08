# -*- encoding: utf-8 -*-
# stub: async 1.30.1 ruby lib

Gem::Specification.new do |s|
  s.name = "async".freeze
  s.version = "1.30.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Samuel Williams".freeze]
  s.date = "2021-07-29"
  s.files = ["lib/async.rb".freeze, "lib/async/barrier.rb".freeze, "lib/async/clock.rb".freeze, "lib/async/condition.rb".freeze, "lib/async/debug/monitor.rb".freeze, "lib/async/debug/selector.rb".freeze, "lib/async/logger.rb".freeze, "lib/async/node.rb".freeze, "lib/async/notification.rb".freeze, "lib/async/queue.rb".freeze, "lib/async/reactor.rb".freeze, "lib/async/scheduler.rb".freeze, "lib/async/semaphore.rb".freeze, "lib/async/task.rb".freeze, "lib/async/version.rb".freeze, "lib/async/wrapper.rb".freeze, "lib/kernel/async.rb".freeze, "lib/kernel/sync.rb".freeze]
  s.homepage = "https://github.com/socketry/async".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.0.9".freeze
  s.summary = "A concurrency framework for Ruby.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<console>.freeze, ["~> 1.10"])
      s.add_runtime_dependency(%q<nio4r>.freeze, ["~> 2.3"])
      s.add_runtime_dependency(%q<timers>.freeze, ["~> 4.1"])
      s.add_development_dependency(%q<async-rspec>.freeze, ["~> 1.1"])
      s.add_development_dependency(%q<bake>.freeze, [">= 0"])
      s.add_development_dependency(%q<benchmark-ips>.freeze, [">= 0"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<covered>.freeze, ["~> 0.10"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.6"])
    else
      s.add_dependency(%q<console>.freeze, ["~> 1.10"])
      s.add_dependency(%q<nio4r>.freeze, ["~> 2.3"])
      s.add_dependency(%q<timers>.freeze, ["~> 4.1"])
      s.add_dependency(%q<async-rspec>.freeze, ["~> 1.1"])
      s.add_dependency(%q<bake>.freeze, [">= 0"])
      s.add_dependency(%q<benchmark-ips>.freeze, [">= 0"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<covered>.freeze, ["~> 0.10"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.6"])
    end
  else
    s.add_dependency(%q<console>.freeze, ["~> 1.10"])
    s.add_dependency(%q<nio4r>.freeze, ["~> 2.3"])
    s.add_dependency(%q<timers>.freeze, ["~> 4.1"])
    s.add_dependency(%q<async-rspec>.freeze, ["~> 1.1"])
    s.add_dependency(%q<bake>.freeze, [">= 0"])
    s.add_dependency(%q<benchmark-ips>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<covered>.freeze, ["~> 0.10"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.6"])
  end
end

