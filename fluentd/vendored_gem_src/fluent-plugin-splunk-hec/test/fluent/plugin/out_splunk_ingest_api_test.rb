# frozen_string_literal: true

require 'test_helper'

describe Fluent::Plugin::SplunkIngestApiOutput do
  include Fluent::Test::Helpers
  include PluginTestHelper

  INGEST_API_ENDPOINT = 'https://api.scp.splunk.com/tenant_name/ingest/v1beta2/events'
  AUTH_TOKEN_ENDPOINT = 'https://auth.scp.splunk.com/token'

  before { Fluent::Test.setup } # setup router and others

  it { expect(::Fluent::Plugin::SplunkIngestApiOutput::VERSION).wont_be_nil }

  describe 'Required configs validation' do
    it 'should have required fields' do
      expect { create_api_output_driver }.must_raise Fluent::ConfigError
    end

    describe 'good_config' do
      it {
        instance = create_api_output_driver('service_client_identifier service_client_id',
                                            'service_client_secret_key secret_key',
                                            'ingest_api_tenant tenant_name').instance
        expect(instance.service_client_identifier).must_equal 'service_client_id'
        expect(instance.service_client_secret_key).must_equal 'secret_key'
        expect(instance.ingest_api_tenant).must_equal 'tenant_name'
      }
    end
    describe 'invalid host' do
      it {
        expect do
          create_api_output_driver('ingest_api_host %bad-host%',
                                   'service_client_identifier service_client_id',
                                   'service_client_secret_key secret_key',
                                   'ingest_api_tenant tenant_name')
        end.must_raise Fluent::ConfigError
      }
    end
    describe 'missing tenant name' do
      it {
        expect do
          create_api_output_driver('ingest_api_host %bad-host%',
                                   'service_client_identifier service_client_id',
                                   'service_client_secret_key secret_key',
                                   'ingest_api_tenant tenant_name')
        end.must_raise Fluent::ConfigError
      }
    end
    describe 'missing client identifier' do
      it {
        expect do
          create_api_output_driver('ingest_api_host %bad-host%',
                                   'service_client_secret_key secret_key',
                                   'ingest_api_tenant tenant_name')
        end.must_raise Fluent::ConfigError
      }
    end

    describe 'missing secret key' do
      it {
        expect do
          create_api_output_driver('ingest_api_host %bad-host%',
                                   'service_client_identifier service_client_id',
                                   'ingest_api_tenant tenant_name')
        end.must_raise Fluent::ConfigError
      }
    end
  end

  it 'should not fail to start when provided bad auth' do
    stub_failed_auth
    driver = create_api_output_driver('service_client_identifier service_client_id',
                                      'service_client_secret_key secret_key',
                                      'ingest_api_tenant tenant_name')
    driver.run
  end

  it 'should send request to Splunk' do
    req = verify_sent_events do |batch|
      expect(batch.size).must_equal 2
    end
    expect(req).must_be_requested times: 1
  end

  it 'should have an index in the attributes slot' do
    verify_sent_events(conf: %(
      index my_index
    )) do |batch|
      batch.each do |item|
        expect(item['attributes']['index']).must_equal 'my_index'
      end
    end
  end

  it 'should have attrbutes not fields' do
    verify_sent_events do |batch|
      batch.each do |item|
        expect(item).wont_include :fields
        expect(item).includes :attributes
      end
    end
  end

  it 'should have body not event' do
    verify_sent_events do |batch|
      batch.each do |item|
        expect(item).wont_include :event
        expect(item).includes :body
      end
    end
  end

  it 'should have a timestamp and nanos' do
    verify_sent_events do |batch|
      batch.each do |item|
        expect(item).wont_include :time
        expect(item).includes :timestamp
        expect(item).includes :nanos
      end
    end
  end

  it 'should raise error on 401/429 to force retry' do
    # Try to quiet this down some.
    report_on_exception = Thread.report_on_exception
    Thread.report_on_exception = false
    begin
      expect do
        verify_sent_events status: 429
      end.must_raise RuntimeError

      expect do
        verify_sent_events status: 401
      end.must_raise RuntimeError
    ensure
      Thread.report_on_exception = report_on_exception
    end
  end

  it 'should not send an empty log message' do
    verify_sent_events conf: %(
      <format>
        @type single_value
        message_key log
        add_newline false
     </format>), event: { 'log' => "\n" } do |batch|
      batch.each do |_item|
        raise 'No message should be sent'
      end
    end
  end

  # it 'should send index from filters' do
  #   verify_sent_events conf: %[
  #     <filter>
  #       @type record_transformer
  #       enable_ruby
  #       <record>
  #           index ${ENV['SPLUNK_INDEX']}
  #       </record>
  #     </filter>
  #   ], event: {"log" => "This is the log", "index" => "indexname"} do |batch|
  #     batch.each do |item|
  #       item[:attrbutes][:index].
  #       fail "No message should be sent"
  #     end
  #   end
  # end

  def create_api_output_driver(*configs)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::SplunkIngestApiOutput).tap do |d|
      d.configure(configs.join("\n"))
    end
  end

  DEFAULT_EVENT = {
    log: 'everything is good',
    level: 'info',
    from: 'my_machine',
    file: 'cool.log',
    value: 100,
    agent: {
      name: 'test',
      version: '1.0.0'
    }
  }.freeze

  def verify_sent_events(args = {})
    conf = args[:conf] || ''
    event = args[:event] || DEFAULT_EVENT
    status = args[:status] || 200

    events = [
      ['tag.event1', event_time, { id: '1st' }.merge(Marshal.load(Marshal.dump(event)))],
      ['tag.event2', event_time, { id: '2nd' }.merge(Marshal.load(Marshal.dump(event)))]
    ]

    @driver = create_api_output_driver('service_client_identifier service_client_id',
                                       'service_client_secret_key secret_key',
                                       'ingest_api_tenant tenant_name',
                                       conf)

    api_req = if status == 200
                stub_successful_api_request.with do |r|
                  yield r.body.split(/(?={)\s*(?<=})/).map { |item| JSON.load item }.first
                end
              else
                stub_failed_api_request status
              end

    @driver.run do
      events.each { |evt| @driver.feed *evt }
    end

    api_req
  end

  def stub_successful_auth
    stub_request(:post, AUTH_TOKEN_ENDPOINT)
      .to_return(body: '{"access_token":"bearer token","token_type":"Bearer","expires_in":432000,"scope":"client_credentials"}')
  end

  def stub_failed_auth
    stub_request(:post, AUTH_TOKEN_ENDPOINT)
      .to_return(status: 401,
                 body: '{"error":"invalid_client","error_description":"The client secret supplied for a confidential client is invalid."}')
  end

  def stub_successful_api_request
    stub_successful_auth

    stub_request(:post, INGEST_API_ENDPOINT)
      .to_return(body: '{"message":"Success","code":"SUCCESS"}')
  end

  def stub_failed_api_request(status)
    stub_successful_auth

    stub_request(:post, INGEST_API_ENDPOINT)
      .to_return(body: '', status: status)
  end
end
