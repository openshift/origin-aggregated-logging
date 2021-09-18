require_relative 'test_helper'
require 'fluent/test/driver/formatter'
require File.join(File.dirname(__FILE__), '..', 'lib/formatter_single_json_value')

class SingleValueFormatterTest < ::Test::Unit::TestCase
  def create_driver(conf = "")
    Fluent::Test::Driver::Formatter.new(Fluent::Plugin::SingleJsonValueFormatter).configure(conf)
  end

  def test_config_params
    d = create_driver
    assert_equal "message", d.instance.message_key
  end

  def test_config_params_message_key
    d = create_driver('message_key' => 'foobar')
    assert_equal "foobar", d.instance.message_key
  end

  def test_format
    d = create_driver
    formatted = d.instance.format('tag', event_time, {'message' => 'awesome'})
    assert_equal("awesome\n", formatted)
  end

  def test_format_json
    d = create_driver
    formatted = d.instance.format('tag', event_time, {'message' => {'key' => 'value'}})
    assert_equal("{\"key\":\"value\"}\n", formatted)
  end

  def test_format_nested_json
    d = create_driver
    formatted = d.instance.format('tag', event_time, {'message' => {'nestedkey' => {'key' => 'value'}}})
    assert_equal("{\"nestedkey\":{\"key\":\"value\"}}\n", formatted)
  end

  def test_format_without_newline
    d = create_driver('add_newline' => 'false')
    formatted = d.instance.format('tag', event_time, {'message' => 'awesome'})
    assert_equal("awesome", formatted)
  end

  def test_format_with_message_key
    d = create_driver('message_key' => 'foobar')
    formatted = d.instance.format('tag', event_time, {'foobar' => 'foo'})

    assert_equal("foo\n", formatted)
  end
end
