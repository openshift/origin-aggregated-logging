require 'fluent/test'
require 'test/unit/rr'
require 'fluent/test/driver/parser'
require 'json'

require File.join(File.dirname(__FILE__), '..', 'lib/parser_viaq_ovn_audit')

class ParserViaqOvnAuditTest < Test::Unit::TestCase
  include Fluent

  setup do
    Fluent::Test.setup
  end

  def create_driver(conf = '')
    Fluent::Test::Driver::Parser.new(ViaqOvnAuditParser).configure(conf)
  end

  sub_test_case 'plugin will parse ovn audit messages' do
    test 'ovn audit logs test' do
      d = create_driver()
      message = "2021-07-06T08:26:58.687Z|00004|acl_log(ovn_pinctrl0)|INFO|name=\"verify-audit-logging_deny-all\", verdict=drop, severity=alert:icmp,vlan_tci=0x0000,dl_src=0a:58:0a:81:02:12,dl_dst=0a:58:0a:81:02:14,nw_src=10.129.2.18,nw_dst=10.129.2.20,nw_tos=0,nw_ecn=0,nw_ttl=64,icmp_type=8,icmp_code=0"
      d.instance.parse(message) do |time, record|
        assert_equal('2021-07-06T08:26:58.687Z', record['@timestamp'])
        assert_equal('info', record['level'])
        assert_equal("\"verify-audit-logging_deny-all\"", record['structured']['name'])
        assert_equal("alert:icmp", record['structured']['severity'])
        assert_true(time.instance_of? Fluent::EventTime)
      end
    end

    test 'ovn audit logs error level' do
      d = create_driver()
      message = "2021-07-06T08:26:58.687Z|00004|acl_log(ovn_pinctrl0)|error|name=\"verify-audit-logging_allow-all\", verdict=drop, severity=alert:icmp,vlan_tci=0x0000,dl_src=0a:58:0a:81:02:12,dl_dst=0a:58:0a:81:02:14,nw_src=10.129.2.18,nw_dst=10.129.2.20,nw_tos=0,nw_ecn=0,nw_ttl=64,icmp_type=8,icmp_code=0"
      d.instance.parse(message) do |time, record|
        assert_equal('error', record['level'])
        assert_equal("\"verify-audit-logging_allow-all\"", record['structured']['name'])
        assert_true(time.instance_of? Fluent::EventTime)
      end
    end

    test 'ovn audit logs structured fields length' do
      d = create_driver()
      message = "2021-07-06T08:26:58.687Z|00004|acl_log(ovn_pinctrl0)|error|name=\"verify-audit-logging_allow-all\", verdict=drop, severity=alert:icmp,vlan_tci=0x0000,dl_src=0a:58:0a:81:02:12,dl_dst=0a:58:0a:81:02:14,nw_src=10.129.2.18,nw_dst=10.129.2.20,nw_tos=0,nw_ecn=0,nw_ttl=64,icmp_type=8,icmp_code=0"
      d.instance.parse(message) do |time, record|
        assert_equal(record['structured'].length, 13)
        assert_true(time.instance_of? Fluent::EventTime)
      end
    end
  end
end
