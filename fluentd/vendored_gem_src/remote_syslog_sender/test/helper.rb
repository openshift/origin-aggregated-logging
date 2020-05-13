$:.unshift File.expand_path('../../lib', __FILE__)

unless ENV['BUNDLE_GEMFILE']
  require 'rubygems'
  require 'bundler'
  Bundler.setup
  Bundler.require
end

require 'remote_syslog_sender'

require 'test/unit'
