require 'fluent/test'
require 'test/unit/rr'
require File.join(File.dirname(__FILE__), '..', 'lib/filter_concat') 

class ConcatFilterTest < Test::Unit::TestCase
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
    d = Test::FilterTestDriver.new(ConcatFilter, 'this.is.a.tag').configure(conf, true)
    d.instance.log_level = 'DEBUG'
    @dlog = d.instance.log
    d
  end

  def emit_with_tag(tag, msg0={}, msg1={}, msg2={}, conf='')
    d = create_driver(conf)
    d.run {
      d.emit_with_tag(tag, msg0, @time)
      d.emit_with_tag(tag, msg1, @time) unless msg1 == {}
      d.emit_with_tag(tag, msg2, @time) unless msg2 == {}
    }.filtered.instance_variable_get(:@record_array)[0]
  end  

  sub_test_case 'configure' do
    test 'check setting all params to non-default values' do
      d = create_driver('
        key log
        partial_key logtag
        partial_value P
      ')
      assert_equal(false, d.instance.keep_partial_key)
      assert_equal('log', d.instance.key)
      assert_equal('logtag', d.instance.partial_key)
      assert_equal('P', d.instance.partial_value)
    end
  end

  sub_test_case 'merge multilines' do
    test 'full log message remains intact' do
      message0 = 'This is a full log message.'
      rec = emit_with_tag('tag', {'log'=>message0, 'logtag'=>'F'}, {}, {}, '
        key log
        partial_key logtag
        partial_value P
      ')
      assert_equal({'log'=>message0}, rec)
    end
    test 'partial log + full log message' do
      message0 = 'First_part'
      message1 = 'Second_part'
      rec = emit_with_tag('tag', {'log'=>message0, 'logtag'=>'P'}, {'log'=>message1, 'logtag'=>'F'}, {}, '
        key log
        partial_key logtag
        partial_value P
      ')
      assert_equal({'log'=>message0+message1}, rec)
    end
    test 'partial log + partial log + full log message' do
      message0 = 'First_part'
      message1 = 'Second_part'
      message2 = 'Thirrd_part'
      rec = emit_with_tag('tag', {'log'=>message0, 'logtag'=>'P'}, {'log'=>message1, 'logtag'=>'P'}, {'log'=>message2, 'logtag'=>'F'}, '
        key log
        partial_key logtag
        partial_value P
      ')
      assert_equal({'log'=>message0+message1+message2}, rec)
    end
  end
end
