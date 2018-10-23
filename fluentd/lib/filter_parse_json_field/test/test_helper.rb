require 'serverengine' # or test will throw error missing method windows?
require "fluent/test"
require 'test/unit/rr'
require "fluent/test/helpers"
require "fluent/test/driver/filter"

Test::Unit::TestCase.include(Fluent::Test::Helpers)
