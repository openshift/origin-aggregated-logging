require 'bundler/gem_tasks'
require 'yard'
require 'rspec/core/rake_task'

unless ENV['RUBOCOP'] == 'false'
  require 'rubocop/rake_task' 

  RuboCop::RakeTask.new(:rubocop) do |task|
    task.patterns = ['lib/**/*.rb', 'spec/**/*.rb']
    task.fail_on_error = false
  end
end

desc 'open a console with systemd/journal required'
task :console do
  exec 'pry -I./lib -r systemd/journal'
end

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
  t.options = ['--no-private', '--markup=markdown']
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w(--color)
end

task default: :spec
