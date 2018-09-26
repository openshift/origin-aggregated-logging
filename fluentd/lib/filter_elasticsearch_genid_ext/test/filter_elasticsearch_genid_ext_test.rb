require 'fluent/test'
require 'test/unit/rr'
require 'json'

require File.join(File.dirname(__FILE__), '..', 'lib/filter_elasticsearch_genid_ext') 

class ElasticsearchGenidExtFilterTest < Test::Unit::TestCase
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
    d = Test::FilterTestDriver.new(ElasticsearchGenidExtFilter, 'this.is.a.tag').configure(conf, true)
    d
  end

  def emit_with_tag(tag, record={}, conf='')
    d = create_driver(conf)
    d.run {
      d.emit_with_tag(tag, record, @time)
    }.filtered.instance_variable_get(:@record_array)[0]
  end  

  sub_test_case 'configure' do
    test 'check setting all params to non-default values' do
      d = create_driver('
        @log_level debug
        hash_id_key viaq_msg_id
        alt_key kubernetes.event.metadata.uid
        alt_tags "kubernetes.var.log.containers.logging-eventrouter-*.** kubernetes.journal.container.kubernetes-event"
      ')
      assert_equal('viaq_msg_id', d.instance.hash_id_key)
      assert_equal('kubernetes.event.metadata.uid', d.instance.alt_key)
    end
  end

  sub_test_case 'generate ids' do
    test 'no alt_key config' do
      record = JSON.parse('{"log":{"message":"a log record"},"key":{"subkey":"0123456789"},"time":"2018-08-22T17:04:12.385850123Z"}')
      rec = emit_with_tag('tag', record, '
        @log_level debug
        hash_id_key viaq_msg_id
      ')
      assert_not_equal('0123456789', rec["viaq_msg_id"])
    end
    test 'record has no alt_key; no alt_tags' do
      record = JSON.parse('{"log":{"message":"a log record"},"key":{"bogus":"0123456789"},"time":"2018-08-22T17:04:12.385850123Z"}')
      rec = emit_with_tag('tag', record, '
        @log_level debug
        hash_id_key viaq_msg_id
        alt_key key.subkey
      ')
      assert_not_equal('0123456789', rec["viaq_msg_id"])
    end
    test 'record has no alt_key; has matched alt_tags' do
      record = JSON.parse('{"log":{"message":"a log record"},"key":{"bogus":"0123456789"},"time":"2018-08-22T17:04:12.385850123Z"}')
      rec = emit_with_tag('kubernetes.var.log.containers.logging-eventrouter-9876543210', record, '
        @log_level debug
        hash_id_key viaq_msg_id
        alt_key key.subkey
        alt_tags "kubernetes.var.log.containers.logging-eventrouter-*.** kubernetes.journal.container.kubernetes-event"
      ')
      assert_not_equal('0123456789', rec["viaq_msg_id"])
    end
    test 'record has alt_key; no alt_tags' do
      record = JSON.parse('{"log":{"message":"a log record"},"key":{"subkey":"0123456789"},"time":"2018-08-22T17:04:12.385850123Z"}')
      rec = emit_with_tag('tag', record, '
        @log_level debug
        hash_id_key viaq_msg_id
        alt_key key.subkey
      ')
      assert_not_equal('0123456789', rec["viaq_msg_id"])
    end
    test 'record has alt_key; has matched alt_tags' do
      record = JSON.parse('{"log":{"message":"a log record"},"key":{"subkey":"0123456789"},"time":"2018-08-22T17:04:12.385850123Z"}')
      rec = emit_with_tag('kubernetes.var.log.containers.logging-eventrouter-9876543210', record, '
        @log_level debug
        hash_id_key viaq_msg_id
        alt_key key.subkey
        alt_tags "kubernetes.var.log.containers.logging-eventrouter-*.** kubernetes.journal.container.kubernetes-event"
      ')
      assert_equal('0123456789', rec["viaq_msg_id"])
    end
  end
end
