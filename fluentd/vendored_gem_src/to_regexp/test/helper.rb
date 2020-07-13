unless RUBY_VERSION >= '1.9'
  require 'rubygems'
end
require 'bundler'
Bundler.setup
require 'test/unit'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'to_regexp'
class Test::Unit::TestCase
end
