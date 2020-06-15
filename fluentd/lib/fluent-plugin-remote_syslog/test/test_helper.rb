require 'bundler/setup'
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require "fluent/test"
require 'fluent/test/driver/output'

require 'test/unit/rr'
