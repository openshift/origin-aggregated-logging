require_relative 'test_helper'
require File.join(File.dirname(__FILE__), '..', 'lib/filter_parse_json_field') 

class ParseJsonFieldFilterTest < Test::Unit::TestCase

  def debugit(driver, msg)
    return
    log = driver.instance.log
    logdev = @driver.instance.log.instance_variable_get(:@logdev)
    logger = log.instance_variable_get(:@logger)
    logger_logger = logger.instance_variable_get(:@logger)
    logger_logger_logdev = logger_logger.instance_variable_get(:@logdev)
    logs = logdev ? logdev.logs : []
    logger_logs = logger_logger_logdev ? logger_logger_logdev.logs : []
    logsid = logs.object_id
    puts "#{msg} driver [#{driver}] log [#{log}] logger [#{logger}] logdev [#{logdev}] logger_logger [#{logger_logger}] logger_logger_logdev [#{logger_logger_logdev}] logs [#{logsid}] [#{logs}] logger_logs [#{logger_logs.object_id}] [#{logger_logs}] @logs [#{@logs.object_id}] [#{@logs}]"
  end

  setup do
    Fluent::Test.setup
    @time = Fluent::Engine.now
    @timestamp = Time.now
    @timestamp_str = @timestamp.utc.to_datetime.rfc3339(6)
    stub(Time).now { @timestamp }
  end

  def create_driver(conf = '')
    d = Fluent::Test::Driver::Filter.new(Fluent::Plugin::ParseJSONFieldFilter).configure(conf)
    @driver = d
    log = d.instance.log
    logdev = log.instance_variable_get(:@logdev)
    logger = log.instance_variable_get(:@logger)
    logger_logger = logger.instance_variable_get(:@logger)
    logger_logger_logdev = logger_logger.instance_variable_get(:@logdev)
    @logs = logdev.logs || logger_logger_logdev.logs || []
    debugit(d, "in create_driver")
    d
  end

  def emit_with_tag(tag, msg={}, conf='')
    d = create_driver(conf)
    d.run {
      d.feed(tag, @time, msg)
    }
    debugit(@driver, 'in emit_with_tag')
    d.filtered.map{|e| e.last}[0]
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
    test 'replace json field' do
      json_string_val = '{"a":{"b":"c"},"d":["e","f"],"g":97,"h":{"i":"j"}}'
      orig_a_value = 'orig a value'
      rec = emit_with_tag('tag', {'message'=>json_string_val, 'a'=>orig_a_value},'
        merge_json_log false
        replace_json_log true
        json_fields message
      ')
      assert_equal({'a'=>{'b'=>'c'}, 'd'=>['e', 'f'], 'g'=>97, 'h'=>{'i'=>'j'}}, rec['message'])
    end
    test 'replace json field no raising NoMethodError for Number' do
      json_string_val = 100
      orig_a_value = 'orig a value'
      assert_nothing_raised(NoMethodError) {
        emit_with_tag('tag', {'message'=>json_string_val, 'a'=>orig_a_value},'
          merge_json_log false
          replace_json_log true
          json_fields message
        ')
      }
    end
    test 'replace json field no raising NoMethodError for Hash' do
      json_string_val = {
        1 => ['a', 'b'],
        2 => ['c'],
        3 => ['d', 'e', 'f', 'g'],
        4 => ['h']
      }
      orig_a_value = 'orig a value'
      assert_nothing_raised(NoMethodError) {
        emit_with_tag('tag', {'message'=>json_string_val, 'a'=>orig_a_value},'
        merge_json_log false
        replace_json_log true
        json_fields message
      ')
      }
    end
    test 'no fallback if parsing error in given field' do
      # test that - skip1 is skipped, skip2 is attempted to parse and fail
      # jsonfield is skipped - message is logged at debug level
      json_string_val2 = '{"k":{"b":"c"},"l":["e","f"],"m":97,"n":{"i":"j"}}'
      orig_a_value = 'orig a value'
      rec = emit_with_tag('tag', {'skip1'=>'{"bogusvalue}', 'a'=>orig_a_value, 'jsonfield'=>json_string_val2},'
        @log_level debug
        json_fields skip1,skip2,jsonfield
      ')
      assert_equal({'skip1'=>'{"bogusvalue}', 'a'=>orig_a_value, 'jsonfield'=>json_string_val2}, rec)
      debugit(@driver, 'in test')
      assert_match /\[debug\]: parse_json_field could not parse field \[skip1\] as JSON: value \[\{"bogusvalue\}\]/, @logs[0]
    end
    test 'fallback if given field is nil' do
      # test that - skip1 is skipped because it has a nil key
      json_string_val2 = '{"k":{"b":"c"},"l":["e","f"],"m":97,"n":{"i":"j"}}'
      orig_a_value = 'orig a value'
      rec = emit_with_tag('tag', {'skip1'=>nil, 'a'=>orig_a_value, 'jsonfield'=>json_string_val2},'
        merge_json_log true
        json_fields skip1,jsonfield
      ')
      assert_equal({'skip1'=>nil, 'a'=>orig_a_value, 'jsonfield'=>json_string_val2}, rec)
      debugit(@driver, 'in test')
    end
  end
end
