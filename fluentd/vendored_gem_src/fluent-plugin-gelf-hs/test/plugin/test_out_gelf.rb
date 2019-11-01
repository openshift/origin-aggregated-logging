require 'test_helper'

class GELFOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONF = %[
    host localhost
  ]

  def create_driver(conf = CONF)
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::GELFOutput).configure(conf) do
      def write(chunk)
        chunk.read
      end
    end
  end

  def test_configure
    d = create_driver
    assert_false d.instance.use_record_host
    assert_false d.instance.add_msec_time
    assert_equal 'localhost', d.instance.host
    assert_equal 12201, d.instance.port
    assert_equal 'udp', d.instance.protocol
    assert_false d.instance.tls
    assert_true d.instance.tls_options.empty?
  end

  def test_format
    d = create_driver
    time = Time.now
    d.emit({"message" => "gelf"}, time.to_i)
    d.expect_format({'_tag' => 'test', 'timestamp' => time.to_i, 'short_message' => 'gelf'}.to_msgpack)
    d.run
  end

  def test_write
    d = create_driver
    time = Time.now
    d.emit({"message" => "gelf"}, time.to_i)
    d.run
  end
end
