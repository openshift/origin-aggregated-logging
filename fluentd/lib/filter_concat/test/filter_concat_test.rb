require 'fluent/test'
require 'test/unit/rr'
require 'rr'
require File.join(File.dirname(__FILE__), '..', 'lib/filter_concat') 

class ConcatFilterTest < Test::Unit::TestCase
  include Fluent

  CONFIG = %[
    key message
    n_lines 3
  ]

  TEST_TAG = 'test'

  setup do
    Fluent::Test.setup
    @time = Fluent::Engine.now
  end

  def create_driver(conf = CONFIG)
    Test::FilterTestDriver.new(ConcatFilter, TEST_TAG).configure(conf, true)
  end

  def filter(conf, messages, wait: nil)
    d = create_driver(conf)
    def d.logs
      @instance.log.logs
    end
    yield d if block_given?
    d.run do
      sleep 0.1 # run event loop
      messages.each do |message|
        d.emit(message, @time)
      end
      sleep wait if wait
    end
    # return an array of records
    d.filtered.collect{|time,record| record}
  end

  def filter_with_time(conf, messages, wait: nil)
    d = create_driver(conf)
    def d.logs
      @instance.log.logs
    end
    yield d if block_given?
    d.run do
      sleep 0.1 # run event loop
      messages.each do |time, message|
        d.emit(message, time)
      end
      sleep wait if wait
    end
    # return an array of [time, record]
    d.filtered.collect{|time,record| [time, record]}
  end

  sub_test_case "crio" do
    test 'full log message remains intact' do
      config = <<-CONFIG
        key log
        partial_key logtag
        partial_value P
        separator ""
      CONFIG
      message0 = 'This is a full log message.'
      rec = filter(config, [{'log'=>message0, 'logtag'=>'F'}])
      assert_equal({'log'=>message0}, rec[0])
    end
    test 'partial log + full log message' do
      config = <<-CONFIG
        key log
        partial_key logtag
        partial_value P
        separator ""
      CONFIG
      message0 = 'First_part'
      message1 = 'Second_part'
      rec = filter(config, [{'log'=>message0, 'logtag'=>'P'}, {'log'=>message1, 'logtag'=>'F'}])
      assert_equal({'log'=>message0+message1}, rec[0])
    end
    test 'partial log + partial log + full log message' do
      config = <<-CONFIG
        key log
        partial_key logtag
        partial_value P
        separator ""
      CONFIG
      message0 = 'First_part'
      message1 = 'Second_part'
      message2 = 'Thirrd_part'
      rec = filter(config, [{'log'=>message0, 'logtag'=>'P'}, {'log'=>message1, 'logtag'=>'P'}, {'log'=>message2, 'logtag'=>'F'}])
      assert_equal({'log'=>message0+message1+message2}, rec[0])
    end
  end

  sub_test_case "multiline docker json" do
    test 'full log message remains intact' do
      config = <<-CONFIG
        key log
        multiline_end_regexp /\\n$/
        separator ""
      CONFIG
      message0 = "This is a full log message.\n"
      rec = filter(config, [{'log'=>message0}])
      assert_equal({'log'=>message0}, rec[0])
    end
    test 'partial log + full log message' do
      config = <<-CONFIG
        key log
        multiline_end_regexp /\\n$/
        separator ""
      CONFIG
      message0 = "First_part"
      message1 = "Second_part\n"
      rec = filter(config, [{'log'=>message0}, {'log'=>message1}])
      assert_equal({'log'=>message0+message1}, rec[0])
    end
    test 'partial log + partial log + full log message' do
      config = <<-CONFIG
        key log
        multiline_end_regexp /\\n$/
        separator ""
      CONFIG
      message0 = "First_part"
      message1 = "Second_part"
      message2 = "Thirrd_part\n"
      rec = filter(config, [{'log'=>message0}, {'log'=>message1}, {'log'=>message2}])
      assert_equal({'log'=>message0+message1+message2}, rec[0])
    end
  end

  sub_test_case "config" do
    test "empty" do
      assert_raise(Fluent::ConfigError.new("'key' parameter is required")) do
        create_driver("")
      end
    end

    test "exclusive" do
      assert_raise(Fluent::ConfigError.new("n_lines and multiline_start_regexp/multiline_end_regexp are exclusive")) do
        create_driver(<<-CONFIG)
          key message
          n_lines 10
          multiline_start_regexp /^start/
        CONFIG
      end
    end

    test "either" do
      assert_raise(Fluent::ConfigError.new("Either n_lines, multiline_start_regexp, multiline_end_regexp, partial_key or use_partial_metadata is required")) do
        create_driver(<<-CONFIG)
          key message
        CONFIG
      end
    end

    test "partial_key with n_lines" do
      assert_raise(Fluent::ConfigError.new("partial_key and n_lines are exclusive")) do
        create_driver(<<-CONFIG)
          key message
          n_lines 10
          partial_key partial_message
        CONFIG
      end
    end

    test "partial_key with multiline_start_regexp" do
      assert_raise(Fluent::ConfigError.new("partial_key and multiline_start_regexp/multiline_end_regexp are exclusive")) do
        create_driver(<<-CONFIG)
          key message
          multiline_start_regexp /xxx/
          partial_key partial_message
        CONFIG
      end
    end

    test "partial_key with multiline_end_regexp" do
      assert_raise(Fluent::ConfigError.new("partial_key and multiline_start_regexp/multiline_end_regexp are exclusive")) do
        create_driver(<<-CONFIG)
          key message
          multiline_end_regexp /xxx/
          partial_key partial_message
        CONFIG
      end
    end

    test "partial_key is specified but partial_value is missing" do
      assert_raise(Fluent::ConfigError.new("partial_value is required when partial_key is specified")) do
        create_driver(<<-CONFIG)
          key message
          partial_key partial_message
        CONFIG
      end
    end

    test "n_lines" do
      d = create_driver
      assert_equal(:line, d.instance.instance_variable_get(:@mode))
    end

    test "multiline_start_regexp" do
      d = create_driver(<<-CONFIG)
        key message
        multiline_start_regexp /^start/
      CONFIG
      assert_equal(:regexp, d.instance.instance_variable_get(:@mode))
    end

    test "multiline_end_regexp" do
      d = create_driver(<<-CONFIG)
        key message
        multiline_end_regexp /^end/
      CONFIG
      assert_equal(:regexp, d.instance.instance_variable_get(:@mode))
    end
  end

  sub_test_case "lines" do
    test "filter" do
      messages = [
        { "host" => "example.com", "message" => "message 1" },
        { "host" => "example.com", "message" => "message 2" },
        { "host" => "example.com", "message" => "message 3" },
      ]
      expected = [
        { "host" => "example.com", "message" => "message 1\nmessage 2\nmessage 3" }
      ]
      filtered = filter(CONFIG, messages)
      assert_equal(expected, filtered)
    end

    test "filter excess" do
      messages = [
        { "host" => "example.com", "message" => "message 1" },
        { "host" => "example.com", "message" => "message 2" },
        { "host" => "example.com", "message" => "message 3" },
        { "host" => "example.com", "message" => "message 4" },
      ]
      expected = [
        { "host" => "example.com", "message" => "message 1\nmessage 2\nmessage 3" }
      ]
      filtered = filter(CONFIG, messages)
      assert_equal(expected, filtered)
    end

    test "filter 2 groups" do
      messages = [
        { "host" => "example.com", "message" => "message 1" },
        { "host" => "example.com", "message" => "message 2" },
        { "host" => "example.com", "message" => "message 3" },
        { "host" => "example.com", "message" => "message 4" },
        { "host" => "example.com", "message" => "message 5" },
        { "host" => "example.com", "message" => "message 6" },
      ]
      expected = [
        { "host" => "example.com", "message" => "message 1\nmessage 2\nmessage 3" },
        { "host" => "example.com", "message" => "message 4\nmessage 5\nmessage 6" },
      ]
      filtered = filter(CONFIG, messages)
      assert_equal(expected, filtered)
    end

    test "missing keys" do
      messages = [
        { "host" => "example.com", "message" => "message 1" },
        { "host" => "example.com", "message" => "message 2" },
        { "host" => "example.com", "message" => "message 3" },
        { "host" => "example.com", "message" => "message 4" },
        { "host" => "example.com", "message" => "message 5" },
        { "host" => "example.com", "message" => "message 6" },
        { "host" => "example.com", "somekey" => "message 7" },
      ]
      expected = [
        { "host" => "example.com", "message" => "message 1\nmessage 2\nmessage 3" },
        { "host" => "example.com", "message" => "message 4\nmessage 5\nmessage 6" },
        { "host" => "example.com", "somekey" => "message 7" },
      ]
      filtered = filter(CONFIG, messages)
      assert_equal(expected, filtered)
    end

    test "stream identity" do
      messages = [
        { "container_id" => "1", "message" => "message 1" },
        { "container_id" => "2", "message" => "message 2" },
        { "container_id" => "1", "message" => "message 3" },
        { "container_id" => "2", "message" => "message 4" },
        { "container_id" => "1", "message" => "message 5" },
        { "container_id" => "2", "message" => "message 6" },
      ]
      expected = [
        { "container_id" => "1", "message" => "message 1\nmessage 3\nmessage 5" },
        { "container_id" => "2", "message" => "message 2\nmessage 4\nmessage 6" },
      ]
      filtered = filter(CONFIG + "stream_identity_key container_id", messages)
      assert_equal(expected, filtered)
    end

    test "timeout" do
      messages = [
        { "container_id" => "1", "message" => "message 1" },
        { "container_id" => "1", "message" => "message 2" },
      ]
      filtered = filter(CONFIG + "flush_interval 2s", messages, wait: 3) do |d|
        errored = { "container_id" => "1", "message" => "message 1\nmessage 2" }
        mock(d.instance.router).emit_error_event(TEST_TAG, anything, errored, anything)
      end
      assert_equal([], filtered)
    end

    test "timeout with timeout_label" do
      messages = [
        { "container_id" => "1", "message" => "message 1" },
        { "container_id" => "1", "message" => "message 2" },
      ]
      filtered = filter(CONFIG + "flush_interval 2s\ntimeout_label @TIMEOUT", messages, wait: 3) do |d|
        errored = { "container_id" => "1", "message" => "message 1\nmessage 2" }
        event_router = mock(Object.new).emit(TEST_TAG, anything, errored)
        label = mock(Object.new).event_router { event_router }
        mock(Fluent::Engine.root_agent).find_label("@TIMEOUT") { label }
      end
      assert_equal([], filtered)
    end

    test "no timeout" do
      messages = [
        { "container_id" => "1", "message" => "message 1" },
        { "container_id" => "1", "message" => "message 2" },
        { "container_id" => "1", "message" => "message 3" },
      ]
      filtered = filter(CONFIG + "flush_interval 30s", messages, wait: 3) do |d|
        errored = { "container_id" => "1", "message" => "message 1\nmessage 2\nmessage 3" }
        mock(d.instance.router).emit_error_event(TEST_TAG, anything, errored, anything).times(0)
      end
      expected = [
        { "container_id" => "1", "message" => "message 1\nmessage 2\nmessage 3" },
      ]
      assert_equal(expected, filtered)
    end
  end

  sub_test_case "regexp" do
    test "filter" do
      config = <<-CONFIG
        key message
        multiline_start_regexp /^start/
      CONFIG
      messages = [
        { "host" => "example.com", "message" => "start" },
        { "host" => "example.com", "message" => "  message 1" },
        { "host" => "example.com", "message" => "  message 2" },
        { "host" => "example.com", "message" => "start" },
        { "host" => "example.com", "message" => "  message 3" },
        { "host" => "example.com", "message" => "  message 4" },
        { "host" => "example.com", "message" => "start" },
      ]
      expected = [
        { "host" => "example.com", "message" => "start\n  message 1\n  message 2" },
        { "host" => "example.com", "message" => "start\n  message 3\n  message 4" },
      ]
      filtered = filter(config, messages)
      assert_equal(expected, filtered)
    end

    test "stream identity" do
      config = <<-CONFIG
        key message
        stream_identity_key container_id
        multiline_start_regexp /^start/
      CONFIG
      messages = [
        { "container_id" => "1", "message" => "start" },
        { "container_id" => "1", "message" => "  message 1" },
        { "container_id" => "1", "message" => "  message 2" },
        { "container_id" => "2", "message" => "start" },
        { "container_id" => "2", "message" => "  message 3" },
        { "container_id" => "2", "message" => "  message 4" },
        { "container_id" => "1", "message" => "start" },
        { "container_id" => "2", "message" => "  message 5" },
        { "container_id" => "2", "message" => "start" },
      ]
      expected = [
        { "container_id" => "1", "message" => "start\n  message 1\n  message 2" },
        { "container_id" => "2", "message" => "start\n  message 3\n  message 4\n  message 5" },
      ]
      filtered = filter(config, messages) do |d|
        errored1 = { "container_id" => "1", "message" => "start" }
        errored2 = { "container_id" => "2", "message" => "start" }
        router = d.instance.router
        mock(router).emit_error_event(TEST_TAG, anything, errored1, anything)
        mock(router).emit_error_event(TEST_TAG, anything, errored2, anything)
      end
      assert_equal(expected, filtered)
    end

    test "multiline_end_regexp" do
      config = <<-CONFIG
        key message
        stream_identity_key container_id
        multiline_start_regexp /^start/
        multiline_end_regexp /^end/
      CONFIG
      messages = [
        { "container_id" => "1", "message" => "start" },
        { "container_id" => "2", "message" => "start" },
        { "container_id" => "1", "message" => "  message 1" },
        { "container_id" => "2", "message" => "  message 3" },
        { "container_id" => "1", "message" => "  message 2" },
        { "container_id" => "2", "message" => "  message 4" },
        { "container_id" => "1", "message" => "end" },
        { "container_id" => "2", "message" => "end" },
      ]
      expected = [
        { "container_id" => "1", "message" => "start\n  message 1\n  message 2\nend" },
        { "container_id" => "2", "message" => "start\n  message 3\n  message 4\nend" },
      ]
      filtered = filter(config, messages)
      assert_equal(expected, filtered)
    end

    test "multiline with single line logs" do
      config = <<-CONFIG
        key message
        stream_identity_key container_id
        multiline_start_regexp /^start/
        multiline_end_regexp /^end/
      CONFIG
      messages = [
        { "container_id" => "1", "message" => "single1" },
        { "container_id" => "2", "message" => "single2" },
        { "container_id" => "1", "message" => "start" },
        { "container_id" => "2", "message" => "start" },
        { "container_id" => "1", "message" => "  message 1" },
        { "container_id" => "2", "message" => "  message 3" },
        { "container_id" => "1", "message" => "  message 2" },
        { "container_id" => "2", "message" => "  message 4" },
        { "container_id" => "1", "message" => "end" },
        { "container_id" => "2", "message" => "end" },
        { "container_id" => "1", "message" => "single3" },
        { "container_id" => "2", "message" => "single4" },
      ]
      expected = [
        { "container_id" => "1", "message" => "single1" },
        { "container_id" => "2", "message" => "single2" },
        { "container_id" => "1", "message" => "start\n  message 1\n  message 2\nend" },
        { "container_id" => "2", "message" => "start\n  message 3\n  message 4\nend" },
        { "container_id" => "1", "message" => "single3" },
        { "container_id" => "2", "message" => "single4" },
      ]
      filtered = filter(config, messages)
      assert_equal(expected, filtered)
    end

    test "multiline_start_regexp and multiline_end_regexp" do
      config = <<-CONFIG
        key message
        stream_identity_key container_id
        multiline_start_regexp /^start/
        multiline_end_regexp /end$/
      CONFIG
      messages = [
        { "container_id" => "1", "message" => "start message end" },
        { "container_id" => "1", "message" => "start" },
        { "container_id" => "1", "message" => " message1" },
        { "container_id" => "1", "message" => " message2" },
        { "container_id" => "1", "message" => "end" },
      ]
      expected = [
        { "container_id" => "1", "message" => "start message end" },
        { "container_id" => "1", "message" => "start\n message1\n message2\nend" },
      ]
      filtered = filter(config, messages)
      assert_equal(expected, filtered)
    end

    test "multiline_end_regexp only" do
      config = <<-CONFIG
        key message
        stream_identity_key container_id
        multiline_end_regexp /\\n$/
      CONFIG
      messages = [
          { "host" => "example.com", "message" => "{\"key1\": \"value1\",\"key2\": \"value2\"}\n" },
          { "host" => "example.com", "message" => "{\"key3\": \"value3\",\"key4\": \"value4\"," },
          { "host" => "example.com", "message" => "\"key5\": \"value5\",\"key6\": \"value6\"," },
          { "host" => "example.com", "message" => "\"key7\": \"value7\",\"key8\": \"value8\"}\n" },
          { "host" => "example.com", "message" => "{\"key9\": \"value9\",\"key0\": \"value0\"," },
          { "host" => "example.com", "message" => "\"key1\": \"value1\",\"key2\": \"value2\"}\n" },
      ]
      expected = [
          { "host" => "example.com","message" => "{\"key1\": \"value1\",\"key2\": \"value2\"}\n" },
          { "host" => "example.com","message" => "{\"key3\": \"value3\",\"key4\": \"value4\",\n\"key5\": \"value5\",\"key6\": \"value6\",\n\"key7\": \"value7\",\"key8\": \"value8\"}\n" },
          { "host" => "example.com","message" => "{\"key9\": \"value9\",\"key0\": \"value0\",\n\"key1\": \"value1\",\"key2\": \"value2\"}\n" },
      ]
      filtered = filter(config, messages)
      assert_equal(expected, filtered)
    end

    # https://github.com/okkez/fluent-plugin-concat/issues/14
    test "multiline_start_regexp and multiline_end_regexp #14" do
      config = <<-CONFIG
        key message
        stream_identity_key container_id
        multiline_start_regexp /^start/
        multiline_end_regexp /end$/
      CONFIG
      messages = [
        { "container_id" => "1", "message" => "start message1 end" },
        { "container_id" => "1", "message" => "start" },
        { "container_id" => "1", "message" => " message3" },
        { "container_id" => "1", "message" => "start message2 end" },
        { "container_id" => "1", "message" => "start" },
        { "container_id" => "1", "message" => " message4" },
        { "container_id" => "1", "message" => "end" },
      ]
      expected = [
        { "container_id" => "1", "message" => "start message1 end" },
        { "container_id" => "1", "message" => "start\n message3" },
        { "container_id" => "1", "message" => "start message2 end" },
        { "container_id" => "1", "message" => "start\n message4\nend" },
      ]
      filtered = filter(config, messages)
      assert_equal(expected, filtered)
    end

    test "timeout" do
      config = <<-CONFIG
        key message
        multiline_start_regexp /^start/
        flush_interval 1s
      CONFIG
      messages = [
        { "container_id" => "1", "message" => "start" },
        { "container_id" => "1", "message" => "  message 1" },
        { "container_id" => "1", "message" => "  message 2" },
      ]
      filtered = filter(config, messages, wait: 3) do |d|
        errored = { "container_id" => "1", "message" => "start\n  message 1\n  message 2" }
        mock(d.instance.router).emit_error_event(TEST_TAG, anything, errored, anything)
      end
      assert_equal([], filtered)
    end

    test "continuous_line_regexp" do
      config = <<-CONFIG
        key message
        multiline_start_regexp /^start/
        continuous_line_regexp /^ /
        flush_interval 1s
      CONFIG
      messages = [
        { "container_id" => "1", "message" => "start" },
        { "container_id" => "1", "message" => "  message 1" },
        { "container_id" => "1", "message" => "  message 2" },
        { "container_id" => "1", "message" => "single line message 1" },
        { "container_id" => "1", "message" => "start" },
        { "container_id" => "1", "message" => "  message 3" },
        { "container_id" => "1", "message" => "  message 4" },
        { "container_id" => "1", "message" => "single line message 2" },
      ]
      filtered = filter(config, messages, wait: 3)
      expected = [
        { "container_id" => "1", "message" => "start\n  message 1\n  message 2" },
        { "container_id" => "1", "message" => "single line message 1" },
        { "container_id" => "1", "message" => "start\n  message 3\n  message 4" },
        { "container_id" => "1", "message" => "single line message 2" },
      ]
      assert_equal(expected, filtered)
    end

    test "missing keys" do
      config = <<-CONFIG
        key message
        multiline_start_regexp /^start/
        continuous_line_regexp /^ /
        flush_interval 1s
      CONFIG
      messages = [
        { "container_id" => "1", "message" => "start" },
        { "container_id" => "1", "message" => "  message 1" },
        { "container_id" => "1", "message" => "  message 2" },
        { "container_id" => "1", "message" => "single line message 1" },
        { "container_id" => "2", "nomessage" => "This is not message" },
        { "container_id" => "1", "message" => "start" },
        { "container_id" => "1", "message" => "  message 3" },
        { "container_id" => "1", "message" => "  message 4" },
        { "container_id" => "1", "message" => "single line message 2" },
      ]
      filtered = filter(config, messages, wait: 3)
      expected = [
        { "container_id" => "1", "message" => "start\n  message 1\n  message 2" },
        { "container_id" => "1", "message" => "single line message 1" },
        { "container_id" => "2", "nomessage" => "This is not message" },
        { "container_id" => "1", "message" => "start\n  message 3\n  message 4" },
        { "container_id" => "1", "message" => "single line message 2" },
      ]
      assert_equal(expected, filtered)
    end

    test "value is nil" do
      config = <<-CONFIG
        key message
        stream_identity_key container_id
        multiline_start_regexp /^start/
        continuous_line_regexp /^ /
        flush_interval 1s
      CONFIG
      messages = [
        { "container_id" => "1", "message" => "start" },
        { "container_id" => "1", "message" => "  message 1" },
        { "container_id" => "1", "message" => "  message 2" },
        { "container_id" => "1", "message" => nil },
        { "container_id" => "1", "message" => "single line message 1" },
        { "container_id" => "1", "message" => "start" },
        { "container_id" => "1", "message" => "  message 3" },
        { "container_id" => "1", "message" => "  message 4" },
        { "container_id" => "1", "message" => "single line message 2" },
      ]
      filtered = filter(config, messages, wait: 3)
      expected = [
        { "container_id" => "1", "message" => "start\n  message 1\n  message 2" },
        { "container_id" => "1", "message" => nil },
        { "container_id" => "1", "message" => "single line message 1" },
        { "container_id" => "1", "message" => "start\n  message 3\n  message 4" },
        { "container_id" => "1", "message" => "single line message 2" },
      ]
      assert_equal(expected, filtered)
    end
  end

  sub_test_case "partial_key" do
    test "filter with docker style events" do
      config = <<-CONFIG
        key message
        partial_key partial_message
        partial_value true
      CONFIG
      messages = [
        { "container_id" => "1", "message" => "start", "partial_message" => "true" },
        { "container_id" => "1", "message" => " message 1", "partial_message" => "true" },
        { "container_id" => "1", "message" => " message 2", "partial_message" => "true" },
        { "container_id" => "1", "message" => "end", "partial_message" => "false" },
        { "container_id" => "1", "message" => "start", "partial_message" => "true" },
        { "container_id" => "1", "message" => " message 3", "partial_message" => "true" },
        { "container_id" => "1", "message" => " message 4", "partial_message" => "true" },
        { "container_id" => "1", "message" => "end", "partial_message" => "false" },
      ]
      filtered = filter(config, messages, wait: 3)
      expected = [
        { "container_id" => "1", "message" => "start\n message 1\n message 2\nend" },
        { "container_id" => "1", "message" => "start\n message 3\n message 4\nend" },
      ]
      assert_equal(expected, filtered)
    end

    test "filter with docker style events keep partial_key" do
      config = <<-CONFIG
        key message
        partial_key partial_message
        partial_value true
        keep_partial_key true
      CONFIG
      messages = [
        { "container_id" => "1", "message" => "start", "partial_message" => "true" },
        { "container_id" => "1", "message" => " message 1", "partial_message" => "true" },
        { "container_id" => "1", "message" => " message 2", "partial_message" => "true" },
        { "container_id" => "1", "message" => "end", "partial_message" => "false" },
        { "container_id" => "1", "message" => "start", "partial_message" => "true" },
        { "container_id" => "1", "message" => " message 3", "partial_message" => "true" },
        { "container_id" => "1", "message" => " message 4", "partial_message" => "true" },
        { "container_id" => "1", "message" => "end", "partial_message" => "false" },
      ]
      filtered = filter(config, messages, wait: 3)
      expected = [
        { "container_id" => "1", "message" => "start\n message 1\n message 2\nend", "partial_message" => "false" },
        { "container_id" => "1", "message" => "start\n message 3\n message 4\nend", "partial_message" => "false" },
      ]
      assert_equal(expected, filtered)
    end

    test "filter with docker style events keep partial_key includes single line event" do
      config = <<-CONFIG
        key message
        partial_key partial_message
        partial_value true
        keep_partial_key true
      CONFIG
      messages = [
        { "container_id" => "1", "message" => "start", "partial_message" => "true" },
        { "container_id" => "1", "message" => " message 1", "partial_message" => "true" },
        { "container_id" => "1", "message" => " message 2", "partial_message" => "true" },
        { "container_id" => "1", "message" => "end", "partial_message" => "false" },
        { "container_id" => "1", "message" => "single line" },
        { "container_id" => "1", "message" => "start", "partial_message" => "true" },
        { "container_id" => "1", "message" => " message 3", "partial_message" => "true" },
        { "container_id" => "1", "message" => " message 4", "partial_message" => "true" },
        { "container_id" => "1", "message" => "end", "partial_message" => "false" },
      ]
      filtered = filter(config, messages, wait: 3)
      expected = [
        { "container_id" => "1", "message" => "start\n message 1\n message 2\nend", "partial_message" => "false" },
        { "container_id" => "1", "message" => "single line" },
        { "container_id" => "1", "message" => "start\n message 3\n message 4\nend", "partial_message" => "false" },
      ]
      assert_equal(expected, filtered)
    end

    test "filter with containerd/cri style events" do
      config = <<-CONFIG
        key message
        partial_key flag
        partial_value P
      CONFIG
      # These messages are parsed by a parser plugin before this plugin will process messages
      messages = [
        { "container_id" => "1", "message" => "start", "flag" => "P" },
        { "container_id" => "1", "message" => " message 1", "flag" => "P" },
        { "container_id" => "1", "message" => " message 2", "flag" => "P" },
        { "container_id" => "1", "message" => "end", "flag" => "F" },
        { "container_id" => "1", "message" => "start", "flag" => "P" },
        { "container_id" => "1", "message" => " message 3", "flag" => "P" },
        { "container_id" => "1", "message" => " message 4", "flag" => "P" },
        { "container_id" => "1", "message" => "end", "flag" => "F" },
      ]
      filtered = filter(config, messages, wait: 3)
      expected = [
        { "container_id" => "1", "message" => "start\n message 1\n message 2\nend" },
        { "container_id" => "1", "message" => "start\n message 3\n message 4\nend" },
      ]
      assert_equal(expected, filtered)
    end
  end

  sub_test_case "partial meta (for Docker 19.03 or later)" do
    test "partial messages only" do
      config = <<-CONFIG
        key message
        use_partial_metadata true
      CONFIG
      messages = [
        {
          "container_id" => "1",
          "message" => "start",
          "partial_message" => "true",
          "partial_id" => "partial1",
          "partial_ordinal" => "1",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => " message 1",
          "partial_message" => "true",
          "partial_id" => "partial1",
          "partial_ordinal" => "2",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => " message 2",
          "partial_message" => "true",
          "partial_id" => "partial1",
          "partial_ordinal" => "3",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => "end",
          "partial_message" => "true",
          "partial_id" => "partial1",
          "partial_ordinal" => "4",
          "partial_last" => "true"
        },
        {
          "container_id" => "1",
          "message" => "start",
          "partial_message" => "true",
          "partial_id" => "partial2",
          "partial_ordinal" => "1",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => " message 3",
          "partial_message" => "true",
          "partial_id" => "partial2",
          "partial_ordinal" => "2",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => " message 4",
          "partial_message" => "true",
          "partial_id" => "partial2",
          "partial_ordinal" => "3",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => "end",
          "partial_message" => "true",
          "partial_id" => "partial2",
          "partial_ordinal" => "4",
          "partial_last" => "true"
        },
      ]
      filtered = filter(config, messages, wait: 3)
      expected = [
        { "container_id" => "1", "message" => "start\n message 1\n message 2\nend" },
        { "container_id" => "1", "message" => "start\n message 3\n message 4\nend" },
      ]
      assert_equal(expected, filtered)
    end

    test "mixed" do
      config = <<-CONFIG
        key message
        use_partial_metadata true
      CONFIG
      messages = [
        {
          "container_id" => "1",
          "message" => "start",
          "partial_message" => "true",
          "partial_id" => "partial1",
          "partial_ordinal" => "1",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => " message 1",
          "partial_message" => "true",
          "partial_id" => "partial1",
          "partial_ordinal" => "2",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => " message 2",
          "partial_message" => "true",
          "partial_id" => "partial1",
          "partial_ordinal" => "3",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => "end",
          "partial_message" => "true",
          "partial_id" => "partial1",
          "partial_ordinal" => "4",
          "partial_last" => "true"
        },
        { "container_id" => "1", "message" => "single line" },
        {
          "container_id" => "1",
          "message" => "start",
          "partial_message" => "true",
          "partial_id" => "partial2",
          "partial_ordinal" => "1",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => " message 3",
          "partial_message" => "true",
          "partial_id" => "partial2",
          "partial_ordinal" => "2",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => " message 4",
          "partial_message" => "true",
          "partial_id" => "partial2",
          "partial_ordinal" => "3",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => "end",
          "partial_message" => "true",
          "partial_id" => "partial2",
          "partial_ordinal" => "4",
          "partial_last" => "true"
        },
      ]
      filtered = filter(config, messages, wait: 3)
      expected = [
        { "container_id" => "1", "message" => "start\n message 1\n message 2\nend" },
        { "container_id" => "1", "message" => "single line" },
        { "container_id" => "1", "message" => "start\n message 3\n message 4\nend" },
      ]
      assert_equal(expected, filtered)
    end

    test "unsorted" do
      config = <<-CONFIG
        key message
        use_partial_metadata true
      CONFIG
      messages = [
        {
          "container_id" => "1",
          "message" => "start",
          "partial_message" => "true",
          "partial_id" => "partial1",
          "partial_ordinal" => "1",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => " message 2",
          "partial_message" => "true",
          "partial_id" => "partial1",
          "partial_ordinal" => "3",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => " message 1",
          "partial_message" => "true",
          "partial_id" => "partial1",
          "partial_ordinal" => "2",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => "end",
          "partial_message" => "true",
          "partial_id" => "partial1",
          "partial_ordinal" => "4",
          "partial_last" => "true"
        },
        { "container_id" => "1", "message" => "single line" },
        {
          "container_id" => "1",
          "message" => "start",
          "partial_message" => "true",
          "partial_id" => "partial2",
          "partial_ordinal" => "1",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => " message 4",
          "partial_message" => "true",
          "partial_id" => "partial2",
          "partial_ordinal" => "3",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => " message 3",
          "partial_message" => "true",
          "partial_id" => "partial2",
          "partial_ordinal" => "2",
          "partial_last" => "false"
        },
        {
          "container_id" => "1",
          "message" => "end",
          "partial_message" => "true",
          "partial_id" => "partial2",
          "partial_ordinal" => "4",
          "partial_last" => "true"
        },
      ]
      filtered = filter(config, messages, wait: 3)
      expected = [
        { "container_id" => "1", "message" => "start\n message 1\n message 2\nend" },
        { "container_id" => "1", "message" => "single line" },
        { "container_id" => "1", "message" => "start\n message 3\n message 4\nend" },
      ]
      assert_equal(expected, filtered)
    end
  end

  sub_test_case "use first timestamp" do
    test "use_first_timestamp true" do
      messages = [
        [@time, { "host" => "example.com", "message" => "message 1" }],
        [@time + 1, { "host" => "example.com", "message" => "message 2" }],
        [@time + 2, { "host" => "example.com", "message" => "message 3" }],
      ]
      expected = [
        [@time, { "host" => "example.com", "message" => "message 1\nmessage 2\nmessage 3" }]
      ]
      conf = CONFIG + "use_first_timestamp true"
      filtered = filter_with_time(conf, messages)
      assert_equal(expected, filtered)
    end

    test "use_first_timestamp false" do
      messages = [
        [@time, { "host" => "example.com", "message" => "message 1" }],
        [@time + 1, { "host" => "example.com", "message" => "message 2" }],
        [@time + 2, { "host" => "example.com", "message" => "message 3" }],
      ]
      expected = [
        [@time + 2, { "host" => "example.com", "message" => "message 1\nmessage 2\nmessage 3" }]
      ]
      conf = CONFIG + "use_first_timestamp false"
      filtered = filter_with_time(conf, messages)
      assert_equal(expected, filtered)
    end

    test "timeout" do
      config = <<-CONFIG
        key message
        multiline_start_regexp /^start/
        flush_interval 1s
        use_first_timestamp true
      CONFIG
      messages = [
        [@time, { "container_id" => "1", "message" => "start" }],
        [@time, { "container_id" => "1", "message" => "  message 1" }],
        [@time, { "container_id" => "1", "message" => "  message 2" }],
        [@time, { "container_id" => "1", "message" => "start" }],
        [@time + 1, { "container_id" => "1", "message" => "  message 3" }],
        [@time + 2, { "container_id" => "1", "message" => "  message 4" }],
      ]
      filtered = filter_with_time(config, messages, wait: 3) do |d|
        errored = { "container_id" => "1", "message" => "start\n  message 3\n  message 4" }
        mock(d.instance.router).emit_error_event(TEST_TAG, @time, errored, anything)
      end
      expected = [
        [@time, { "container_id" => "1", "message" => "start\n  message 1\n  message 2" }]
      ]
      assert_equal(expected, filtered)
    end

    test "disable timeout" do
      config = <<-CONFIG
        key message
        multiline_start_regexp /^start/
        flush_interval 0s
        use_first_timestamp true
      CONFIG
      messages = [
        [@time, { "container_id" => "1", "message" => "start" }],
        [@time, { "container_id" => "1", "message" => "  message 1" }],
        [@time, { "container_id" => "1", "message" => "  message 2" }],
        [@time, { "container_id" => "1", "message" => "start" }],
      ]
      filtered = filter_with_time(config, messages, wait: 3) do |d|
        mock(d.instance).flush_timeout_buffer.at_most(0)
        errored = { "container_id" => "1", "message" => "start" }
        mock(d.instance.router).emit_error_event(TEST_TAG, @time, errored, anything)
      end
      expected = [
        [@time, { "container_id" => "1", "message" => "start\n  message 1\n  message 2" }]
      ]
      assert_equal(expected, filtered)
    end
  end

  sub_test_case "raise exception in on_timer" do
    # See also https://github.com/fluent/fluentd/issues/1946
    test "failed to flush timeout buffer" do
      config = <<-CONFIG
        key message
        flush_interval 1s
        multiline_start_regexp /^start/
      CONFIG
      messages = [
        { "container_id" => "1", "message" => "start" },
        { "container_id" => "1", "message" => "  message 1" },
        { "container_id" => "1", "message" => "  message 2" },
        { "container_id" => "1", "message" => "start" },
        { "container_id" => "1", "message" => "  message 3" },
        { "container_id" => "1", "message" => "  message 4" },
        { "container_id" => "1", "message" => "start" },
      ]
      lastrec = messages[-1]
      logs = nil
      filtered = filter(config, messages, wait: 3) do |d|
        mock(d.instance).flush_timeout_buffer.times(3) { raise StandardError, "timeout" }
        mock(d.instance.router).emit_error_event(TEST_TAG, anything, lastrec, anything)
        logs = d.logs
      end
      expected = [
        { "container_id" => "1", "message" => "start\n  message 1\n  message 2" },
        { "container_id" => "1", "message" => "start\n  message 3\n  message 4" }
      ]
      expected_logs = [
        "[error]: failed to flush timeout buffer error=#<StandardError: timeout>",
        "[error]: failed to flush timeout buffer error=#<StandardError: timeout>",
        "[error]: failed to flush timeout buffer error=#<StandardError: timeout>",
        "[info]: Flush remaining buffer: test:default"
      ]
      log_messages = logs.map do |line|
        line.chomp.gsub(/.+? (\[(?:error|info)\].+)/) {|m| $1 }
      end
      assert_equal(expected_logs, log_messages)
      assert_equal(expected, filtered)
    end
  end
end
