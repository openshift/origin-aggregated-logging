require "test_helper"
require "fluent/plugin/out_remote_syslog"

class RemoteSyslogOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::RemoteSyslogOutput).configure(conf)
  end

  def test_configure
    d = create_driver %[
      @type remote_syslog
      hostname foo.com
      host example.com
      port 5566
      severity debug
      program minitest
    ]

    loggers = d.instance.instance_variable_get(:@senders)
    assert_equal loggers, []

    assert_equal "example.com", d.instance.instance_variable_get(:@host)
    assert_equal 5566, d.instance.instance_variable_get(:@port)
    assert_equal "debug", d.instance.instance_variable_get(:@severity)
  end

  def test_write
    d = create_driver %[
      @type remote_syslog
      hostname foo.com
      host example.com
      port 5566
      severity debug
      program minitest

      <format>
        @type single_value
        message_key message
      </format>
    ]

    mock.proxy(RemoteSyslogSender::UdpSender).new("example.com", 5566, whinyerrors: true, program: "minitest") do |sender|
      mock.proxy(sender).transmit("foo",  facility: "user", severity: "debug", program: "minitest", hostname: "foo.com")
    end

    d.run do
      d.feed("tag", Fluent::EventTime.now, {"message" => "foo"})
    end
  end

  def test_write_tcp
    d = create_driver %[
      @type remote_syslog
      hostname foo.com
      host example.com
      port 5566
      severity debug
      program minitest

      protocol tcp

      <format>
        @type single_value
        message_key message
      </format>
    ]

    any_instance_of(RemoteSyslogSender::TcpSender) do |klass|
      mock(klass).connect
    end

    mock.proxy(RemoteSyslogSender::TcpSender).new("example.com", 5566, whinyerrors: true, program: "minitest", tls: false, packet_size: 1024, timeout: nil, timeout_exception: false, keep_alive: false, keep_alive_cnt: nil, keep_alive_idle: nil, keep_alive_intvl: nil) do |sender|
      mock(sender).transmit("foo",  facility: "user", severity: "debug", program: "minitest", hostname: "foo.com")
    end

    d.run do
      d.feed("tag", Fluent::EventTime.now, {"message" => "foo"})
    end
  end
end
