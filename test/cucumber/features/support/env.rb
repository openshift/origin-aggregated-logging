require 'tempfile'
require 'yaml'
require 'json'
require 'watir'
require 'digest/sha1'
require 'set'

basedir = File.dirname(__FILE__)
require "#{basedir}/../../lib/openshift-cliwrapper-ruby/lib/openshift_cli_wrapper"

if (ENV['HEADLESS']||'true').downcase == 'true'
  require 'headless'
  headless = Headless.new(destroy_at_exit: true, reuse: true)
  headless.start
end
