require "test_helper"

describe Fluent::Plugin::SplunkHecOutput do
  include Fluent::Test::Helpers
  include PluginTestHelper

  before { Fluent::Test.setup } # setup router and others
    
  it { expect(::Fluent::Plugin::SplunkHecOutput::VERSION).wont_be_nil }

  describe "config param tests" do
      it "should require https protocol" do
        expect(create_output_driver('hec_host protocol').instance.protocol).must_equal :https
      end
      it "should require hec_host" do
        expect(create_output_driver('hec_host hec_host').instance.hec_host).must_equal "hec_host"
      end
      it "should require hec_port" do
        expect(create_output_driver('hec_host hec_port').instance.hec_port).must_equal 8088
      end
      it "should require hec_token" do
        expect(create_output_driver('hec_host hec_token').instance.hec_token).must_equal "some-token"
      end
      it "should define client_cert as nil initially" do
        assert_nil(create_output_driver('hec_host hec_token').instance.client_cert)
      end
      it "should define client_key as nil (string) initially" do
        assert_nil(create_output_driver('hec_host hec_token').instance.client_key)
        expect(create_output_driver('hec_host hec_token').instance.client_key).is_a? String
      end
      it "should define ca_file as nil (string) initially" do
        assert_nil(create_output_driver('hec_host hec_token').instance.ca_file)
        expect(create_output_driver('hec_host hec_token').instance.ca_file).is_a? String
      end
      it "should define ca_path as nil (string) initially" do
        assert_nil(create_output_driver('hec_host hec_token').instance.ca_path)
        expect(create_output_driver('hec_host hec_token').instance.ca_path).is_a? String
      end
      it "should define ssl_ciphers as nil (array) initially" do
        assert_nil(create_output_driver('hec_host hec_token').instance.ssl_ciphers)
        expect(create_output_driver('hec_host hec_token').instance.ssl_ciphers).is_a? Array
      end
      it "should not allow an insecure ssl connection" do
        expect(create_output_driver('hec_host hec_token').instance.insecure_ssl).must_equal false
      end
      it "should allow both event (default) and metric to be sent to splunk" do
        expect(create_output_driver('hec_host hec_token').instance.data_type).must_equal :event
        expect(create_output_driver('hec_host hec_token').instance.data_type = :metric).must_equal :metric
      end
      it "should define Splunk index to index (string) as nil initially" do
        assert_nil(create_output_driver('hec_host hec_token').instance.index)
        expect(create_output_driver('hec_host hec_token').instance.index).is_a? String
      end
      it "should define field names to include Splunk index_key as nil (string) initially" do
        assert_nil(create_output_driver('hec_host hec_token').instance.index_key)
        expect(create_output_driver('hec_host hec_token').instance.index_key).is_a? String
      end
  end

  describe "hec_host validation" do
    describe "invalid host" do
      it "should require hec_host" do
	      expect{ create_output_driver }.must_raise Fluent::ConfigError
      end

      it { expect{ create_output_driver('hec_host %bad-host%') }.must_raise Fluent::ConfigError }
    end

    describe "good host" do
      it {
	      expect(create_output_driver('hec_host splunk.com').instance.hec_host).must_equal "splunk.com"
      }
    end
  end

  it "should send request to Splunk" do
    req = verify_sent_events { |batch|
      expect(batch.size).must_equal 2
    }
    expect(req).must_be_requested times: 1
  end

  it "should use string for event time, and the value of the string should be a float" do
    verify_sent_events { |batch|
      batch.each do |item|
        expect(item['time']).must_be_instance_of String
        expect(item['time']).must_match /^\d+\.\d+$/
      end
    }
  end

  # it "should contain splunk event time field via fluentd, as nil" do
  #   expect(create_output_driver('hec_host splunk.com').instance.time_key).must_equal nil
  # end
  #
  it "should contain splunk event time field via fluentd, as nil" do
        test_driver = create_output_driver('hec_host splunk.com')
        assert_nil(test_driver.instance.time_key)
  end

  it "should use host machine's hostname for event host by default" do
    verify_sent_events { |batch|
      batch.each do |item|
	      expect(item['host']).must_equal Socket.gethostname
      end
    }
  end

  %w[index source sourcetype].each do |field|
    it "should not set #{field} by default" do
      verify_sent_events { |batch|
	    batch.each do |item|
        expect(item).wont_include field
	    end
      }
    end
  end

  it "should support ${tag}" do
    verify_sent_events(<<~CONF) { |batch|
    index ${tag}
    host ${tag}
    source ${tag}
    sourcetype ${tag}
    CONF
      batch.each do |item|
	    %w[index host source sourcetype].each { |field|
	      expect(%w[tag.event1 tag.event2]).must_include item[field]
	    }
      end
    }
  end

  it "should support *_key" do
    verify_sent_events(<<~CONF) { |batch|
      index_key      level
      host_key       from
      source_key     file
      sourcetype_key agent.name
    CONF
      batch.each { |item|
        expect(item['index']).must_equal 'info'
        expect(item['host']).must_equal 'my_machine'
        expect(item['source']).must_equal 'cool.log'
        expect(item['sourcetype']).must_equal 'test'

	JSON.load(item['event']).tap do |event|
	  %w[level from file].each { |field| expect(event).wont_include field }
	  expect(event['agent']).wont_include 'name'
	end
      }
    }
  end

  it "should remove nil fields." do
    verify_sent_events(<<~CONF) { |batch|
      index_key      nonexist
      host_key       nonexist
      source_key     nonexist
      sourcetype_key nonexist
    CONF
      batch.each { |item|
	expect(item).wont_be :has_key?, 'index'
	expect(item).wont_be :has_key?, 'host'
	expect(item).wont_be :has_key?, 'source'
	expect(item).wont_be :has_key?, 'sourcetype'
      }
    }
  end

  describe 'formatter' do
    it "should support replace the default json formatter" do
      verify_sent_events(<<~CONF) { |batch|
	<format>
	  @type single_value
	  message_key log
	  add_newline false
	</format>
      CONF
	batch.map { |item| item['event'] }
	     .each { |event| expect(event).must_equal "everything is good" }
      }
    end

    it "should support multiple formatters" do
      verify_sent_events(<<~CONF) { |batch|
	source ${tag}
	<format tag.event1>
	  @type single_value
	  message_key log
	  add_newline false
	</format>
      CONF
	expect(batch.find { |item| item['source'] == 'tag.event1' }['event']).must_equal "everything is good"
	expect(batch.find { |item| item['source'] == 'tag.event2' }['event']).must_be_instance_of Hash
      }
    end
  end

  it "should support fields for indexed field extraction" do
    verify_sent_events(<<~CONF) { |batch|
    <fields>
      from
      logLevel level
      nonexist
    </fields>
    CONF
      batch.each do |item|
	JSON.load(item['event']).tap { |event|
	  expect(event).wont_include 'from'
	  expect(event).wont_include 'level'
	}

	expect(item['fields']['from']).must_equal 'my_machine'
	expect(item['fields']['logLevel']).must_equal 'info'
	expect(item['fields']).wont_be :has_key?, 'nonexist'
      end
    }
  end

  describe 'metric'do
    it 'should check related configs' do
      expect(
	      create_output_driver('hec_host somehost', 'data_type metric')
      ).wont_be_nil

      expect{
	      create_output_driver('hec_host somehost', 'data_type metric', 'metrics_from_event false')
      }.must_raise Fluent::ConfigError

      expect{
	      create_output_driver('hec_host somehost', 'data_type metric', 'metric_name_key x')
      }.must_raise Fluent::ConfigError

      expect(
	      create_output_driver('hec_host somehost', 'data_type metric', 'metric_name_key x', 'metric_value_key y')
      ).wont_be_nil
    end

    it 'should have "metric" as event, and have proper fields' do
      verify_sent_events(<<~CONF) { |batch|
      data_type metric
      metric_name_key from
      metric_value_key value
      CONF
      batch.each do |item|
        expect(item['event']).must_equal 'metric'
        expect(item['fields']['metric_name']).must_equal 'my_machine'
        expect(item['fields']['_value']).must_equal 100
        expect(item['fields']['log']).must_equal 'everything is good'
        expect(item['fields']['level']).must_equal 'info'
        expect(item['fields']['file']).must_equal 'cool.log'
	    end
      }
    end

    it 'should handle empty fields' do
      verify_sent_events(<<~CONF) { |batch|
      data_type metric
      metric_name_key from
      metric_value_key value
      <fields>
      </fields>
      CONF
      batch.each do |item|
	  # only "metric_name" and "_value"
	      expect(item['fields'].keys.size).must_equal 2
	    end
      }
    end

    it 'should handle custom fields' do
      verify_sent_events(<<~CONF) { |batch|
      data_type metric
      metric_name_key from
      metric_value_key value
      <fields>
        level
        filePath file
        username
      </fields>
      CONF
      batch.each do |item|
        expect(item['fields'].keys.size).must_equal 4
        expect(item['fields']['level']).must_equal 'info'
        expect(item['fields']['filePath']).must_equal 'cool.log'
        # null fields should be removed
        expect(item['fields']).wont_be :has_key?, 'username'
	    end
      }
    end

    it 'should treat each key-value in event as a metric' do
      metrics = [
        ['tag', event_time, {'cup': 0.5, 'memory': 100}],
        ['tag', event_time, {'cup': 0.6, 'memory': 200}]
      ]
      with_stub_hec(events: metrics, conf: 'data_type metric') { |batch|
	      expect(batch.size).must_equal 4
      }
    end
  end

  describe 'timeout params' do
      it 'should reset unused connection after 5 seconds' do
        expect(create_output_driver('hec_host splunk.com', 'idle_timeout 5').instance.idle_timeout).must_equal 5
      end

      it 'should allow custom setting between reading chunks from the socket' do
        expect(create_output_driver('hec_host splunk.com', 'read_timeout 5').instance.read_timeout).must_equal 5
      end

      it 'should allow custom setting a connection to be opened' do
        expect(create_output_driver('hec_host splunk.com',  'open_timeout 5').instance.open_timeout).must_equal 5
      end

      it 'should check default values are created correctly for timeout params' do
        test_driver = create_output_driver('hec_host splunk.com')
        expect(test_driver.instance.idle_timeout).must_equal 5
        assert_nil(test_driver.instance.read_timeout)
        assert_nil(test_driver.instance.open_timeout)
      end
    end

  def with_stub_hec(events:, conf: '', &blk)
    host = "hec.splunk.com"
    @driver = create_output_driver("hec_host #{host}", conf)

    hec_req = stub_hec_request("https://#{host}:8088").with { |r|
      blk.call r.body.split(/(?={)\s*(?<=})/).map { |item| JSON.load item }
    }

    @driver.run do
      events.each { |evt| @driver.feed *evt }
    end

    hec_req
  end

  def verify_sent_events(conf = '', &blk)
    event = {
      "log"   => "everything is good",
      "level" => "info",
      "from"  => "my_machine",
      "file"  => "cool.log",
      "value" => 100,
      "agent" => {
	      "name"    => "test",
	      "version" => "1.1.0"
      }
    }
    events = [
      ["tag.event1", event_time, {"id" => "1st"}.merge(Marshal.load(Marshal.dump(event)))],
      ["tag.event2", event_time, {"id" => "2nd"}.merge(Marshal.load(Marshal.dump(event)))]
    ]

    with_stub_hec conf: conf, events: events, &blk
  end
end
