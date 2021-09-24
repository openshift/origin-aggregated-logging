#
# Copyright 2019- Banzai Cloud
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "helper"
require "fluent/plugin/out_label_router.rb"

class LabelRouterOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  private

  def create_driver(conf)
    d = Fluent::Test::Driver::BaseOwner.new(Fluent::Plugin::LabelRouterOutput)
    d.extend(Fluent::Test::Driver::EventFeeder)
    Fluent::Engine.root_agent.define_singleton_method(:find_label) do |label_name|
      obj = Object.new
      obj.define_singleton_method(:event_router){ d.instance.router } # for test...
      obj
    end
    d.configure(conf)
  end

  sub_test_case 'test_routing' do
    test 'basic configuration' do
      routing_conf = %(
<route>
  <match>
    labels app:app1
  </match>
  <match>
    labels app2:app2
    negate true
  </match>
  tag new_app_tag
</route>
<route>
  <match>
    labels app:app1
    namespaces default,test
  </match>
  <match>
    labels app:app2
    namespaces system
    negate true
  </match>
  tag new_app_tag
</route>
<route>
  <match>
    labels app:nginx
    namespaces dev,sandbox
  </match>
</route>
<route>
  <match>
    labels app:nginx
    namespaces dev,sandbox
    container_names mycontainer
  </match>
</route>
)
      d = Fluent::Test::Driver::BaseOwner.new(Fluent::Plugin::LabelRouterOutput)
      d.configure(routing_conf)

      r1 = Fluent::Plugin::LabelRouterOutput::Route.new(d.instance.routes[0], nil,nil)
      # Selector matched: GO
      assert_equal(true, r1.match?(labels: { 'app' => 'app1' }, namespace: ''))
      # Exclude match: NO GO
      assert_equal(false, r1.match?(labels: { 'app' => 'app2' }, namespace: ''))
      # Nothing matched: NO GO
      assert_equal(false, r1.match?(labels: { 'app3' => 'app2' }, namespace: ''))

      r2 = Fluent::Plugin::LabelRouterOutput::Route.new(d.instance.routes[1], nil,nil)
      # Match selector and namespace: GO
      assert_equal(true, r2.match?(labels: { 'app' => 'app1' }, namespace: 'test'))
      # Exclude via namespace
      assert_equal(false, r2.match?(labels: { 'app' => 'app2' }, namespace: 'system'))
      # Nothing matched: NO GO
      assert_equal(false, r2.match?(labels: { 'app3' => 'app' }, namespace: 'system'))

      r3 = Fluent::Plugin::LabelRouterOutput::Route.new(d.instance.routes[2], nil,nil)
      assert_equal(true, r3.match?(labels: { 'app' => 'nginx' }, namespace: 'dev'))
      assert_equal(true, r3.match?(labels: { 'app' => 'nginx' }, namespace: 'sandbox'))
      assert_equal(false, r3.match?(labels: { 'app' => 'nginx2' }, namespace: 'sandbox'))

      r4 = Fluent::Plugin::LabelRouterOutput::Route.new(d.instance.routes[3], nil,nil)
      # Matching container name
      assert_equal(true, r4.match?(labels: { 'app' => 'nginx' }, namespace: 'dev', container: 'mycontainer'))
      # Missing container name is equal to wrong container
      assert_equal(false, r4.match?(labels: { 'app' => 'nginx' }, namespace: 'sandbox'))
      # Wrong container name
      assert_equal(false, r4.match?(labels: { 'app' => 'nginx' }, namespace: 'dev', container: 'mycontainer2'))
      # Wrong label but good namespace and container_name
      assert_equal(false, r4.match?(labels: { 'app' => 'nginx2' }, namespace: 'sandbox',  container_name: 'mycontainer2'))
    end
  end

  sub_test_case 'test_tag' do
    test 'normal' do
      CONFIG = %[
<route>
  <match>
    labels app:app1
  </match>
  tag new_app_tag
</route>
]
      event_time = event_time("2019-07-17 11:11:11 UTC")
      d = create_driver(CONFIG)
      d.run(default_tag: 'test') do
        d.feed(event_time, {"kubernetes" => {"labels" => {"app" => "app1"} } } )
      end
      d.run(default_tag: 'test2') do
        d.feed(event_time, {"kubernetes" => {"labels" => {"app" => "app2"} } } )
      end
      events = d.events

      assert_equal(1, events.size)
      assert_equal ["new_app_tag", event_time, {"kubernetes" => {"labels" => {"app" => "app1"} } }], events[0]
    end
  end


  sub_test_case 'test_multiple_events_batched' do
    test 'normal' do
      conf = %[
<route>
  <match>
  </match>
</route>
]
      event_time = event_time("2019-07-17 11:11:11 UTC")
      d = create_driver(conf)
      d.run(expect_emits: 1, expect_records: 2) do
        d.feed("test", [
          [event_time, {"kubernetes" => {} } ],
          [event_time, {"kubernetes" => {} } ],
        ])
      end
    end
  end

  sub_test_case 'test_default_router' do
    test 'normal' do
      CONFIG2 = %[
<route>
  <match>
    labels app:app1
  </match>
  tag new_app_tag
</route>
default_route @default
default_tag "new_tag"
]
      event_time = event_time("2019-07-17 11:11:11 UTC")
      d = create_driver(CONFIG2)
      d.run() do
        d.feed("test", [
          [event_time, {"kubernetes" => {"labels" => {"app" => "app1"} } } ],
          [event_time, {"kubernetes" => {"labels" => {"app" => "app2"} } } ],
        ])
      end
      events = d.events

      assert_equal(2, events.size)
      assert_equal ["new_app_tag", event_time, {"kubernetes" => {"labels" => {"app" => "app1"} } }], events[0]
      assert_equal ["new_tag", event_time, {"kubernetes" => {"labels" => {"app" => "app2"} } }], events[1]
    end
  end

  sub_test_case 'test_empty_router' do
    test 'normal' do
      CONFIG3 = %[
<route>
  tag new_app_tag
  <match>
    labels
    namespaces
  </match>
</route>
]
      event_time = event_time("2019-07-17 11:11:11 UTC")
      d = create_driver(CONFIG3)
      d.run(default_tag: 'test') do
        d.feed(event_time, {"kubernetes" => {"labels" => {"app" => "app1"} } } )
      end
      d.run(default_tag: 'test2') do
        d.feed(event_time, {"kubernetes" => {"labels" => {"app" => "app2"} } } )
      end
      events = d.events

      assert_equal(2, events.size)
      assert_equal ["new_app_tag", event_time, {"kubernetes" => {"labels" => {"app" => "app1"} } }], events[0]
      assert_equal ["new_app_tag", event_time, {"kubernetes" => {"labels" => {"app" => "app2"} } }], events[1]
    end
  end

    sub_test_case 'test_metrics' do
      test 'normal' do
        CONFIG4 = %[
  @id xxx
  metrics true
  <route>
    metrics_labels {"id": "test"}
    tag new_app_tag
    <match>
      labels
      namespaces
    </match>
  </route>
  ]
        event_time = event_time("2019-07-17 11:11:11 UTC")
        d = create_driver(CONFIG4)
        d.run(default_tag: 'test') do
          d.feed(event_time, {"kubernetes" => {"labels" => {"app" => "app1"} } } )
        end
        d.run(default_tag: 'test2') do
          d.feed(event_time, {"kubernetes" => {"labels" => {"app" => "app2"} } } )
        end
        events = d.events

        assert_equal(2, events.size)
        assert_equal ["new_app_tag", event_time, {"kubernetes" => {"labels" => {"app" => "app1"} } }], events[0]
        assert_equal ["new_app_tag", event_time, {"kubernetes" => {"labels" => {"app" => "app2"} } }], events[1]
      end
    end

end
