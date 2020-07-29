require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'fluent/plugin/out_splunk_hec'

require 'fluent/test'
require 'fluent/test/driver/output'
require 'fluent/test/helpers'
require 'minitest/autorun'
require 'webmock/minitest'

# make assertions from webmock available in minitest/spec
module Minitest::Expectations
  infect_an_assertion :assert_requested, :must_be_requested, :reverse
  infect_an_assertion :assert_not_requested, :wont_be_requested, :reverse
end

TEST_HEC_TOKEN = 'some-token'.freeze

module PluginTestHelper
  def fluentd_conf_for(*lines)
    basic_config = [
      "hec_token #{TEST_HEC_TOKEN}"
    ]
    (basic_config + lines).join("\n")
  end

  def create_output_driver(*configs)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::SplunkHecOutput).tap { |d|
      d.configure(fluentd_conf_for(*configs))
    }
  end

  def stub_hec_request(endpoint)
    stub_request(:post, "#{endpoint}/services/collector")
      .with(headers: { 'Authorization' => "Splunk #{TEST_HEC_TOKEN}",
                         'User-Agent' => "fluent-plugin-splunk_hec_out/#{Fluent::Plugin::SplunkHecOutput::VERSION}" })
      .to_return(body: '{"text":"Success","code":0}')
  end
end
