require_relative 'test_helper'
require 'fluent/test'
require 'test/unit/rr'
require File.join(File.dirname(__FILE__), '..', 'lib/filter_parse_json_field') 

class ParseJsonFieldFilterTest < Test::Unit::TestCase
  include Fluent

  setup do
    Fluent::Test.setup
    @time = Fluent::Engine.now
    log = Fluent::Engine.log
    @timestamp = Time.now
    @timestamp_str = @timestamp.utc.to_datetime.rfc3339(6)
    stub(Time).now { @timestamp }
  end

  def create_driver(conf = '')
    d = Test::FilterTestDriver.new(ParseJSONFieldFilter, 'this.is.a.tag').configure(conf, true)
    d.instance.log_level = 'DEBUG'
    @dlog = d.instance.log
    d
  end

  def emit_with_tag(tag, msg={}, conf='')
    d = create_driver(conf)
    d.run {
      d.emit_with_tag(tag, msg, @time)
    }.filtered.instance_variable_get(:@record_array)[0]
  end  

  sub_test_case 'configure' do
    test 'check default' do
      d = create_driver
      assert_equal(true, d.instance.merge_json_log)
      assert_equal(true, d.instance.preserve_json_log)
      assert_equal(['MESSAGE', 'log'], d.instance.json_fields)
    end
    test 'check setting all params to non-default values' do
      d = create_driver('
        merge_json_log false
        preserve_json_log false
        json_fields a,b,c
      ')
      assert_equal(false, d.instance.merge_json_log)
      assert_equal(false, d.instance.preserve_json_log)
      assert_equal(['a','b','c'], d.instance.json_fields)
    end
  end

  sub_test_case 'json parsing' do
    test 'setting merge_json_log false causes no parsing to occur' do
      json_string_val = '{"a":{"b":"c"},"d":["e","f"],"g":97,"h":{"i":"j"}}'
      orig_a_value = 'orig a value'
      rec = emit_with_tag('tag', {'MESSAGE'=>json_string_val, 'a'=>orig_a_value}, '
        merge_json_log false
      ')
      assert_equal({'MESSAGE'=>json_string_val, 'a'=>orig_a_value}, rec)
    end
    test 'parse a MESSAGE field value' do
      json_string_val = '{"a":{"b":"c"},"d":["e","f"],"g":97,"h":{"i":"j"}}'
      orig_a_value = 'orig a value'
      rec = emit_with_tag('tag', {'MESSAGE'=>json_string_val, 'a'=>orig_a_value})
      assert_equal(json_string_val, rec['MESSAGE'])
      assert_equal(orig_a_value, rec['a'])
      assert_equal(['e', 'f'], rec['d'])
      assert_equal(97, rec['g'])
      assert_equal({'i'=>'j'}, rec['h'])
    end
    test 'parse a MESSAGE field value with preseve_json_log false' do
      json_string_val = '{"a":{"b":"c"},"d":["e","f"],"g":97,"h":{"i":"j"}}'
      orig_a_value = 'orig a value'
      rec = emit_with_tag('tag', {'MESSAGE'=>json_string_val, 'a'=>orig_a_value}, '
        preserve_json_log false
      ')
      assert_equal(nil, rec['MESSAGE'])
      assert_equal(orig_a_value, rec['a'])
      assert_equal(['e', 'f'], rec['d'])
      assert_equal(97, rec['g'])
      assert_equal({'i'=>'j'}, rec['h'])
    end
    test 'parse a "log" field value' do
      json_string_val = '{"a":{"b":"c"},"d":["e","f"],"g":97,"h":{"i":"j"}}'
      orig_a_value = 'orig a value'
      rec = emit_with_tag('tag', {'log'=>json_string_val, 'a'=>orig_a_value})
      assert_equal(json_string_val, rec['log'])
      assert_equal(orig_a_value, rec['a'])
      assert_equal(['e', 'f'], rec['d'])
      assert_equal(97, rec['g'])
      assert_equal({'i'=>'j'}, rec['h'])
    end
    test 'parse a given field value' do
      json_string_val = '{"a":{"b":"c"},"d":["e","f"],"g":97,"h":{"i":"j"}}'
      json_string_val2 = '{"k":{"b":"c"},"l":["e","f"],"m":97,"n":{"i":"j"}}'
      orig_a_value = 'orig a value'
      rec = emit_with_tag('tag', {'jsonfield'=>json_string_val, 'a'=>orig_a_value, 'skip2'=>json_string_val2},'
        json_fields skip1,jsonfield,skip2
      ')
      assert_equal(json_string_val, rec['jsonfield'])
      assert_equal(json_string_val2, rec['skip2'])
      assert_equal(orig_a_value, rec['a'])
      assert_equal(['e', 'f'], rec['d'])
      assert_equal(97, rec['g'])
      assert_equal({'i'=>'j'}, rec['h'])
      assert_equal(nil, rec['k'])
      assert_equal(nil, rec['l'])
      assert_equal(nil, rec['m'])
      assert_equal(nil, rec['n'])
    end
    test 'no fallback if parsing error in given field' do
      # test that - skip1 is skipped, skip2 is attempted to parse and fail
      # jsonfield is skipped - message is logged at debug level
      json_string_val2 = '{"k":{"b":"c"},"l":["e","f"],"m":97,"n":{"i":"j"}}'
      orig_a_value = 'orig a value'
      rec = emit_with_tag('tag', {'skip1'=>'{"bogusvalue}', 'a'=>orig_a_value, 'jsonfield'=>json_string_val2},'
        json_fields skip1,skip2,jsonfield
      ')
      assert_equal({'skip1'=>'{"bogusvalue}', 'a'=>orig_a_value, 'jsonfield'=>json_string_val2}, rec)
      assert_match /\[debug\]: parse_json_field could not parse field \[skip1\] as JSON: value \[\{"bogusvalue\}\]/, @dlog.logs[0]
    end
  end
end
