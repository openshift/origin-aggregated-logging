require "test_helper"
require "fluent/plugin/in_collected_tail_monitor"

class CollectedTailMonitorInputTest < Test::Unit::TestCase
  include Fluent

  def setup
    Fluent::Test.setup
  end

  MONITOR_CONFIG = %[
  @type tail
     path /tmp/tmp.log, /var/log/containers/mypodname_mynamespace_mycontainername-34646d7fb38199129ab8d0e6f41833d26e1826cba92571100fd6c53904a5317e.log
  
  @type collected_tail_monitor
    <labels>
      tag mytag
      host example.com
    </labels>
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

  def create_driver(conf)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::CollectedTailMonitorInput).configure(conf)
  end

  def test_configure
    d = create_driver(MONITOR_CONFIG)
  end

  def test_labels_applied_to_metrics
    conf = MONITOR_CONFIG
    puts "passing this #{conf}"
    d = create_driver(conf)
    beforerunlabels = d.instance.instance_variable_get(:@base_labels)
    puts "before base labels set to ...#{beforerunlabels}"
    d.run {
    d.instance.update_monitor_info()
    postrunlabels = d.instance.instance_variable_get(:@base_labels)
    path = "/tmp/tmp.log"
    mergedlabels  = d.instance.labels({"plugin_id" => "mypluginid", "type" => "input_plugin"}, path)
    puts "with logfilepath as #{path} post merging base labels set to ...#{mergedlabels}"

    path = "/var/log/containers/mypodname_mynamespace_mycontainername-34646d7fb38199129ab8d0e6f41833d26e1826cba92571100fd6c53904a5317e.log"
    newmergedlabels  = d.instance.labels({"plugin_id" => "mypluginid", "type" => "input_plugin"}, path)
    puts "with logfilepath as #{path} post merging base labels set to ...#{newmergedlabels}"

    assert_equal('mynamespace',newmergedlabels[:namespace])
    assert_equal('mycontainername',newmergedlabels[:containername])
    assert_equal('mypodname',newmergedlabels[:podname])
    }
 end 

  def test_invalid_configure
      assert_raise(Fluent::ConfigError) {
        d = create_driver(INVALID_MONITOR_CONFIG)
      }
  end

  test 'emit' do
    d = create_driver(MONITOR_CONFIG)
    d.run(timeout: 0.5)

    d.events.each do |tag, time, record|
      assert_equal('input.test', tag)
      assert_equal({'plugin_id' => 'fluentd','type' => 'tail'}, record)
      assert(time.is_a?(Fluent::EventTime))
    end
  end

end
