require "test_helper"
require "fluent/plugin/in_collected_tail_monitor"

class CollectedTailMonitorInputTest < Test::Unit::TestCase
  include Fluent

  def setup
    Fluent::Test.setup
  end

  MONITOR_CONFIG = %[
  @type collected_tail_monitor
  <metric>
    name log_collected_bytes_total
    type counter
    desc Total bytes collected from file
    <labels>
      tag ${tag}
      hostname ${hostname}
    </labels>
  </metric>
]

  INVALID_MONITOR_CONFIG = %[
  @type collected_tail_monitor

  <labels>
    host ${hostname}
    foo bar
    invalid_use1 $.foo.bar
    invalid_use2 $[0][1]
  </labels>
  ]

  def create_driver(conf = MONITOR_CONFIG)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::CollectedTailMonitorInput).configure(conf)
  end

  def test_configure
    d = create_driver(MONITOR_CONFIG)
  end

  def test_invalid_configure
      assert_raise(Fluent::ConfigError) {
        d = create_driver(INVALID_MONITOR_CONFIG)
      }
  end


end
