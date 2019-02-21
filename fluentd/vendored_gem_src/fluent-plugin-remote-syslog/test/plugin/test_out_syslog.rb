require 'helper'

class SyslogOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    remote_syslog 127.0.0.1
    port    25
    hostname      testhost
    remove_tag_prefix        test
    severity  debug
    facility user
    payload_key message
  ]

  def create_driver(conf=CONFIG,tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::SyslogOutput, tag).configure(conf)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }
    assert_raise(Fluent::ConfigError) {
      d = create_driver %[
      hostname      testhost
      remove_tag_prefix        test
      ]
    }
    assert_nothing_raised {
      d = create_driver %[
        remote_syslog 127.0.0.1
      ]
    }
    assert_nothing_raised {
      d = create_driver %[
        remote_syslog 127.0.0.1
        port    639
      ]
    }
    assert_nothing_raised {
      d = create_driver %[
        remote_syslog 127.0.0.1
        port    25
        hostname      deathstar
      ]
    }
    assert_nothing_raised {
      d = create_driver %[
       remote_syslog 127.0.0.1
        port    25
        hostname      testhost
        remove_tag_prefix        test123
      ]
    }
    assert_nothing_raised {
      d = create_driver %[
        remote_syslog 127.0.0.1
        port    25
        hostname      testhost
        remove_tag_prefix        test
        tag_key   tagtag
        severity  debug
      ]
    }
    assert_nothing_raised {
      d = create_driver %[
        remote_syslog 127.0.0.1
        port    25
        hostname      testhost
        remove_tag_prefix        test
        tag_key   tagtag
        severity  debug
        facility user
      ]
    }
    assert_nothing_raised {
      d = create_driver %[
        remote_syslog 127.0.0.1
        port    25
        hostname      testhost
        remove_tag_prefix        test
        tag_key   tagtag
        severity  debug
        facility user
        payload_key message
      ]
    }
    d = create_driver %[
        remote_syslog 127.0.0.1
        port    25
        hostname      testhost
        remove_tag_prefix        test
        tag_key   tagtag
        severity  debug
        facility user
        payload_key message
    ]
    assert_equal 25, d.instance.port
    assert_equal "127.0.0.1", d.instance.remote_syslog
    assert_equal "testhost", d.instance.hostname
    assert_equal Regexp.new('^' + Regexp.escape("test")), d.instance.remove_tag_prefix
    assert_equal "tagtag", d.instance.tag_key
    assert_equal "debug", d.instance.severity
    assert_equal "user", d.instance.facility
    assert_equal "message", d.instance.payload_key

  end
  def test_emit
    d1 = create_driver(CONFIG, 'test.in')
    d1.run do
      d1.emit({'message' => 'asd asd'})
      d1.emit({'message' => 'dsa xasd'})
      d1.emit({'message' => 'ddd ddddd'})
      d1.emit({'message' => '7sssss8 ssssdasd'})
      d1.emit({'message' => 'aaassddffg asdasdasfasf'})
    end
    assert_equal 0, d1.emits.size

  end

  def test_emit_with_time_and_without_time
    d1 = create_driver(CONFIG, 'test.in')
    d1.run do
      d1.emit({'message' => 'asd asd', 'time' => '2007-01-31 12:22:26'})
      d1.emit({'message' => 'dsa xasd'})
      d1.emit({'message' => 'ddd ddddd', 'time' => '2007-03-01 12:22:26'})
      d1.emit({'message' => '7sssss8 ssssdasd', 'time' => '2011-03-01 12:22:26'})
      d1.emit({'message' => 'aaassddffg asdasdasfasf', 'time' => '2016-03-01 12:22:26'})
    end
    assert_equal 0, d1.emits.size

  end


end
