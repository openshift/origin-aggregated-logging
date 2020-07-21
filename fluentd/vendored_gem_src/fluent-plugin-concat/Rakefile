require "bundler/gem_tasks"
require "rake/testtask"
task :default => :test

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = Dir["test/**/test_*.rb"].sort
  t.verbose = false
  t.warning = false
end
