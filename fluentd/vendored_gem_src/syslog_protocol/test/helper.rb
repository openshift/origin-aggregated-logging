$:.unshift File.expand_path('../../lib', __FILE__)

unless ENV['BUNDLE_GEMFILE']
  require 'rubygems'
  require 'bundler'
  Bundler.setup
  Bundler.require
end

require 'bacon'
Bacon.summary_at_exit

require 'syslog_protocol'