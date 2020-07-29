require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/test*.rb'] + FileList['test/**/*_spec.rb']
  t.verbose = true
end

task :default => [:test]