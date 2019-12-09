#
# Fluentd Viaq Data Model Filter Plugin - Ensure records coming from Fluentd
# use the correct Viaq data model formatting and fields.
#
# Copyright 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#require_relative '../helper'
require 'fluent/test'
require 'test/unit/rr'

require 'fluent/plugin/filter_viaq_data_model'

class ViaqDataModelFilterTest < Test::Unit::TestCase
  include Fluent

  setup do
    Fluent::Test.setup
    @time = Fluent::Engine.now
    log = Fluent::Engine.log
    @timestamp = Time.now
    @timestamp_str = @timestamp.utc.to_datetime.rfc3339(6)
    stub(Time).now { @timestamp }
  end

  def create_driver(conf = '')
    d = Test::FilterTestDriver.new(ViaqDataModelFilter, 'this.is.a.tag').configure(conf, true)
    @dlog = d.instance.log
    d
  end

  sub_test_case 'configure' do
    test 'check default' do
      d = create_driver
      assert_equal([], d.instance.default_keep_fields)
      assert_equal([], d.instance.extra_keep_fields)
      assert_equal(['message'], d.instance.keep_empty_fields)
      assert_equal(false, d.instance.use_undefined)
      assert_equal('undefined', d.instance.undefined_name)
      assert_equal(true, d.instance.rename_time)
      assert_equal('time', d.instance.src_time_name)
      assert_equal('@timestamp', d.instance.dest_time_name)
    end
    test 'check various settings' do
      d = create_driver('
        default_keep_fields a,b,c
        extra_keep_fields d,e,f
        keep_empty_fields g,h,i
        use_undefined true
        undefined_name j
        rename_time false
        src_time_name k
        dest_time_name l
      ')
      assert_equal(['a','b','c'], d.instance.default_keep_fields)
      assert_equal(['d','e','f'], d.instance.extra_keep_fields)
      assert_equal(['g','h','i'], d.instance.keep_empty_fields)
      assert_equal(true, d.instance.use_undefined)
      assert_equal('j', d.instance.undefined_name)
      assert_equal(false, d.instance.rename_time)
      assert_equal('k', d.instance.src_time_name)
      assert_equal('l', d.instance.dest_time_name)
    end
    test 'error if undefined_name in default_keep_fields' do
      assert_raise(Fluent::ConfigError) {
        d = create_driver('
          default_keep_fields a
          use_undefined true
          undefined_name a
        ')
      }
    end
    test 'error if undefined_name in extra_keep_fields' do
      assert_raise(Fluent::ConfigError) {
        d = create_driver('
          extra_keep_fields a
          use_undefined true
          undefined_name a
        ')
      }
    end
    test 'error if src_time_field not in default_keep_fields' do
      assert_raise(Fluent::ConfigError) {
        d = create_driver('
          default_keep_fields a
          use_undefined true
          rename_time true
          src_time_name b
        ')
      }
    end
    test 'error if src_time_field not in extra_keep_fields' do
      assert_raise(Fluent::ConfigError) {
        d = create_driver('
          extra_keep_fields a
          use_undefined true
          rename_time true
          src_time_name b
        ')
      }
    end
    test 'static elasticsearch_index_name without static_index_name' do
      assert_raise(Fluent::ConfigError) {
        d = create_driver('
      <elasticsearch_index_name>
        tag "**"
        name_type static
      </elasticsearch_index_name>
        ')
      }
    end
  end

  sub_test_case 'filtering' do
    def emit_with_tag(tag, msg={}, conf='')
      d = create_driver(conf)
      d.run {
        d.emit_with_tag(tag, msg, @time)
      }.filtered.instance_variable_get(:@record_array)[0]
    end
    test 'see if undefined fields are kept at top level' do
      rec = emit_with_tag('tag', {'a'=>'b'})
      assert_equal('b', rec['a'])
    end
    test 'see if undefined fields are put in undefined field except for kept fields' do
      rec = emit_with_tag('tag', {'a'=>'b','c'=>'d','e'=>'f'}, '
        use_undefined true
        default_keep_fields c
        extra_keep_fields e
        rename_time false
      ')
      assert_equal('b', rec['undefined']['a'])
      assert_equal('d', rec['c'])
      assert_equal('f', rec['e'])
    end
    test 'see if undefined fields are put in custom field except for kept fields' do
      rec = emit_with_tag('tag', {'a'=>'b','c'=>'d','e'=>'f'}, '
        use_undefined true
        undefined_name custom
        default_keep_fields c
        extra_keep_fields e
        rename_time false
      ')
      assert_equal('b', rec['custom']['a'])
      assert_equal('d', rec['c'])
      assert_equal('f', rec['e'])
    end
    test 'see if specified empty fields are kept at top level' do
      rec = emit_with_tag('tag', {'a'=>'b','c'=>'','d'=>{}}, '
        keep_empty_fields c,d
      ')
      assert_equal('b', rec['a'])
      assert_equal('', rec['c'])
      assert_equal({}, rec['d'])
    end
    test 'see if time field is renamed' do
      rec = emit_with_tag('tag', {'a'=>'b'}, '
        rename_time true
        src_time_name a
        dest_time_name c
      ')
      assert_equal('b', rec['c'])
      assert_nil(rec['a'])
    end
    test 'see if time field is renamed when checking if missing' do
      rec = emit_with_tag('tag', {'a'=>'b'}, '
        rename_time_if_missing true
        src_time_name a
        dest_time_name c
      ')
      assert_equal('b', rec['c'])
      assert_nil(rec['a'])
    end
    test 'see if time field is renamed when already present' do
      rec = emit_with_tag('tag', {'a'=>'b','c'=>'d'}, '
        rename_time true
        src_time_name a
        dest_time_name c
      ')
      assert_equal('b', rec['c'])
      assert_nil(rec['a'])
    end
    test 'see if time field is preserved when already present' do
      rec = emit_with_tag('tag', {'a'=>'b','c'=>'d'}, '
        rename_time_if_missing true
        src_time_name a
        dest_time_name c
      ')
      assert_equal('d', rec['c'])
      assert_nil(rec['a'])
    end
    test 'see if deeply nested empty fields are removed or preserved' do
      msg = {'a'=>{'b'=>{'c'=>{'d'=>{'e'=>'','f'=>{},'g'=>''}}}},'h'=>{'i'=>{'j'=>'','k'=>'l','m'=>99,'n'=>true}}}
      rec = emit_with_tag('tag', msg)
      assert_nil(rec['a'])
      assert_equal('l', rec['h']['i']['k'])
      assert_equal(99, rec['h']['i']['m'])
      assert_true(rec['h']['i']['n'])
    end
    test 'see if fields with a value of numeric 0 are removed or preserved' do
      msg = {'a'=>{'b'=>{'c'=>{'d'=>{'e'=>'','f'=>{},'g'=>0}}}},'h'=>{'i'=>{'j'=>'','k'=>'l','m'=>0,'n'=>true}}}
      rec = emit_with_tag('tag', msg)
      assert_nil(rec['a']['b']['c']['d']['e'])
      assert_nil(rec['a']['b']['c']['d']['f'])
      assert_equal(0, rec['a']['b']['c']['d']['g'])
      assert_equal('l', rec['h']['i']['k'])
      assert_equal(0, rec['h']['i']['m'])
      assert_true(rec['h']['i']['n'])
    end
    test 'see if fields with array values of numeric values are preserved' do
      msg = {'a'=>{'b'=>{'c'=>{'d'=>{'e'=>'','f'=>{},'g'=>[99.999]}}}},'h'=>{'i'=>{'j'=>'','k'=>'l','m'=>[88],'n'=>true}}}
      rec = emit_with_tag('tag', msg)
      assert_equal([99.999], rec['a']['b']['c']['d']['g'])
      assert_nil(rec['a']['b']['c']['d']['e'])
      assert_nil(rec['a']['b']['c']['d']['f'])
      assert_equal('l', rec['h']['i']['k'])
      assert_equal([88], rec['h']['i']['m'])
      assert_true(rec['h']['i']['n'])
    end
  end

  sub_test_case 'formatters and elasticsearch index names' do
    def emit_with_tag(tag, msg={}, conf='')
      d = create_driver(conf)
      d.run {
        d.emit_with_tag(tag, msg, @time)
      }.filtered.instance_variable_get(:@record_array)[0]
    end

    def normal_input
      {
        "_AUDIT_LOGINUID"            => "AUDIT_LOGINUID",
        "_AUDIT_SESSION"             => "AUDIT_SESSION",
        "_BOOT_ID"                   => "BOOT_ID",
        "_CAP_EFFECTIVE"             => "CAP_EFFECTIVE",
        "_CMDLINE"                   => "CMDLINE",
        "_COMM"                      => "COMM",
        "_EXE"                       => "EXE",
        "_GID"                       => "GID",
        "_MACHINE_ID"                => "MACHINE_ID",
        "_LINE_BREAK"                => "LINE_BREAK",
        "_PID"                       => "PID",
        "_SELINUX_CONTEXT"           => "SELINUX_CONTEXT",
        "_STREAM_ID"                 => "STREAM_ID",
        "_SYSTEMD_CGROUP"            => "SYSTEMD_CGROUP",
        "_SYSTEMD_INVOCATION_ID"     => "SYSTEMD_INVOCATION_ID",
        "_SYSTEMD_OWNER_UID"         => "SYSTEMD_OWNER_UID",
        "_SYSTEMD_SESSION"           => "SYSTEMD_SESSION",
        "_SYSTEMD_SLICE"             => "SYSTEMD_SLICE",
        "_SYSTEMD_UNIT"              => "SYSTEMD_UNIT",
        "_SYSTEMD_USER_UNIT"         => "SYSTEMD_USER_UNIT",
        "_TRANSPORT"                 => "TRANSPORT",
        "_UID"                       => "UID",
        "CODE_FILE"                  => "CODE_FILE",
        "CODE_FUNCTION"              => "CODE_FUNCTION",
        "CODE_LINE"                  => "CODE_LINE",
        "ERRNO"                      => "ERRNO",
        "MESSAGE_ID"                 => "MESSAGE_ID",
        "RESULT"                     => "RESULT",
        "UNIT"                       => "UNIT",
        "SYSLOG_FACILITY"            => "SYSLOG_FACILITY",
        "SYSLOG_IDENTIFIER"          => "SYSLOG_IDENTIFIER",
        "SYSLOG_PID"                 => "SYSLOG_PID",
        "_KERNEL_DEVICE"             => "KERNEL_DEVICE",
        "_KERNEL_SUBSYSTEM"          => "KERNEL_SUBSYSTEM",
        "_UDEV_SYSNAME"              => "UDEV_SYSNAME",
        "_UDEV_DEVNODE"              => "UDEV_DEVNODE",
        "_UDEV_DEVLINK"              => "UDEV_DEVLINK",
        "_SOURCE_REALTIME_TIMESTAMP" => "1501176466216527",
        "__REALTIME_TIMESTAMP"       => "1501176466216527",
        "MESSAGE"                    => "hello world",
        "PRIORITY"                   => "6",
        "_HOSTNAME"                  => "myhost"
      }
    end
    def normal_output_t
      {
        "AUDIT_LOGINUID"        =>"AUDIT_LOGINUID",
        "AUDIT_SESSION"         =>"AUDIT_SESSION",
        "BOOT_ID"               =>"BOOT_ID",
        "CAP_EFFECTIVE"         =>"CAP_EFFECTIVE",
        "CMDLINE"               =>"CMDLINE",
        "COMM"                  =>"COMM",
        "EXE"                   =>"EXE",
        "GID"                   =>"GID",
        "MACHINE_ID"            =>"MACHINE_ID",
        "LINE_BREAK"            =>"LINE_BREAK",
        "PID"                   =>"PID",
        "SELINUX_CONTEXT"       =>"SELINUX_CONTEXT",
        "STREAM_ID"             =>"STREAM_ID",
        "SYSTEMD_INVOCATION_ID" =>"SYSTEMD_INVOCATION_ID",
        "SYSTEMD_CGROUP"        =>"SYSTEMD_CGROUP",
        "SYSTEMD_OWNER_UID"     =>"SYSTEMD_OWNER_UID",
        "SYSTEMD_SESSION"       =>"SYSTEMD_SESSION",
        "SYSTEMD_SLICE"         =>"SYSTEMD_SLICE",
        "SYSTEMD_UNIT"          =>"SYSTEMD_UNIT",
        "SYSTEMD_USER_UNIT"     =>"SYSTEMD_USER_UNIT",
        "TRANSPORT"             =>"TRANSPORT",
        "UID"                   =>"UID"
      }
    end
    def normal_output_u
      {
        "CODE_FILE"         =>"CODE_FILE",
        "CODE_FUNCTION"     =>"CODE_FUNCTION",
        "CODE_LINE"         =>"CODE_LINE",
        "ERRNO"             =>"ERRNO",
        "MESSAGE_ID"        =>"MESSAGE_ID",
        "RESULT"            =>"RESULT",
        "UNIT"              =>"UNIT",
        "SYSLOG_FACILITY"   =>"SYSLOG_FACILITY",
        "SYSLOG_IDENTIFIER" =>"SYSLOG_IDENTIFIER",
        "SYSLOG_PID"        =>"SYSLOG_PID"
      }
    end
    def normal_output_k
      {
        "KERNEL_DEVICE"    =>"KERNEL_DEVICE",
        "KERNEL_SUBSYSTEM" =>"KERNEL_SUBSYSTEM",
        "UDEV_SYSNAME"     =>"UDEV_SYSNAME",
        "UDEV_DEVNODE"     =>"UDEV_DEVNODE",
        "UDEV_DEVLINK"     =>"UDEV_DEVLINK"
      }
    end
    def add_event(input)
      input = input.merge({})
      input['verb'] = 'ADDED'
      input['event'] = {'message'=>'event message','metadata'=>{'creationTimestamp'=>'2017-07-27T17:23:46.216527+00:00'}}
      input
    end
    test 'match records with journal_system_record_tag' do
      rec = emit_with_tag('journal.system', {'a'=>'b', 'MESSAGE'=>'here'}, '
        <formatter>
          tag "**do_not_match**"
          type sys_journal
          remove_keys a,message
        </formatter>
        <formatter>
          tag "journal.system**"
          type sys_journal
        </formatter>
        <formatter>
          tag "**"
          type sys_journal
          remove_keys a,message
        </formatter>
      ')
      assert_equal('b', rec['a'])
      assert_equal('here', rec['message'])
    end
    test 'do not match records without journal_system_record_tag' do
      rec = emit_with_tag('journal.systm', {'a'=>'b', 'MESSAGE'=>'here'}, '
        <formatter>
          tag "journal.system**"
          type sys_journal
        </formatter>
      ')
      assert_equal('b', rec['a'])
      assert_equal('here', rec['MESSAGE'])
    end
    test 'process a journal record, default settings' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      rec = emit_with_tag('journal.system', normal_input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        pipeline_type normalizer
      ')
      assert_equal(normal_output_t, rec['systemd']['t'])
      assert_equal(normal_output_u, rec['systemd']['u'])
      assert_equal(normal_output_k, rec['systemd']['k'])
      assert_equal('hello world', rec['message'])
      assert_equal('info', rec['level'])
      assert_equal('myhost', rec['hostname'])
      assert_equal('2017-07-27T17:27:46.216527+00:00', rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['normalizer']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['normalizer']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['normalizer']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['normalizer']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['normalizer']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['normalizer']['received_at'])
      assert_equal(false, rec.key?('docker'))
      dellist = 'log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'disable journal record processing' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      rec = emit_with_tag('journal.system', normal_input, '
        <formatter>
          enabled false
          tag "journal.system**"
          type sys_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        pipeline_type normalizer
      ')
      assert_nil(rec['systemd'])
      notdellist = 'log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID'.split(',')
      notdellist.each{|field| assert_equal(normal_input[field], rec[field])}
    end
    test 'process a journal record, override remove_keys' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      rec = emit_with_tag('journal.system', normal_input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
          remove_keys CONTAINER_NAME,PRIORITY
        </formatter>
        pipeline_type normalizer
      ')
      assert_equal(normal_output_t, rec['systemd']['t'])
      assert_equal(normal_output_u, rec['systemd']['u'])
      assert_equal(normal_output_k, rec['systemd']['k'])
      assert_equal('hello world', rec['message'])
      assert_equal('info', rec['level'])
      assert_equal('myhost', rec['hostname'])
      assert_equal('2017-07-27T17:27:46.216527+00:00', rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['normalizer']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['normalizer']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['normalizer']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['normalizer']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['normalizer']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['normalizer']['received_at'])
      keeplist = 'log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID'.split(',')
      keeplist.each{|field| normal_input[field] && assert_not_nil(rec[field])}
      dellist = 'CONTAINER_NAME,PRIORITY'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'try a PRIORITY value that is too large' do
      rec = emit_with_tag('journal.system', {'a'=>'b', 'PRIORITY'=>'10'}, '
        <formatter>
          tag "journal.system**"
          type sys_journal
        </formatter>
      ')
      assert_equal('b', rec['a'])
      assert_equal('unknown', rec['level'])
    end
    test 'try a PRIORITY value that is too small' do
      rec = emit_with_tag('journal.system', {'a'=>'b', 'PRIORITY'=>'-1'}, '
        <formatter>
          tag "journal.system**"
          type sys_journal
        </formatter>
      ')
      assert_equal('b', rec['a'])
      assert_equal('unknown', rec['level'])
    end
    test 'try a PRIORITY value that is not a number' do
      rec = emit_with_tag('journal.system', {'a'=>'b', 'PRIORITY'=>'NaN'}, '
        <formatter>
          tag "journal.system**"
          type sys_journal
        </formatter>
      ')
      assert_equal('b', rec['a'])
      assert_equal('unknown', rec['level'])
    end
    test 'try a PRIORITY value that is a floating point number' do
      rec = emit_with_tag('journal.system', {'a'=>'b', 'PRIORITY'=>'1.0'}, '
        <formatter>
          tag "journal.system**"
          type sys_journal
        </formatter>
      ')
      assert_equal('b', rec['a'])
      assert_equal('unknown', rec['level'])
    end
    test 'try a PRIORITY value that is a number' do
      rec = emit_with_tag('journal.system', {'a'=>'b', 'PRIORITY'=>4}, '
        <formatter>
          tag "journal.system**"
          type sys_journal
        </formatter>
      ')
      assert_equal('b', rec['a'])
      assert_equal('warning', rec['level'])
    end
    test 'test with fallback to __REALTIME_TIMESTAMP' do
      input = normal_input.reject{|k,v| k == '_SOURCE_REALTIME_TIMESTAMP'}
      rec = emit_with_tag('journal.system', input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
        </formatter>
      ')
      assert_equal('2017-07-27T17:27:46.216527+00:00', rec['@timestamp'])
    end
    test 'test using internal time if no timestamp given' do
      input = normal_input.reject do |k,v|
        k == '_SOURCE_REALTIME_TIMESTAMP' || k == '__REALTIME_TIMESTAMP'
      end
      rec = emit_with_tag('journal.system', input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
        </formatter>
      ')
      assert_equal(Time.at(@time).utc.to_datetime.rfc3339(6), rec['@timestamp'])
    end
    test 'test system containers' do
      input = normal_input.merge({
        'CONTAINER_ID' => 'container-id',
        'CONTAINER_ID_FULL' => 'container-id-full',
        'CONTAINER_NAME' => 'container-name'
      })
      rec = emit_with_tag('journal.system', input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
        </formatter>
      ')
      assert_equal('container-name', rec['docker']['container_name'])
      assert_equal('container-id', rec['docker']['container_id_short'])
      assert_equal('container-id-full', rec['docker']['container_id'])
    end
    test 'process a kubernetes journal record, default settings' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      rec = emit_with_tag('kubernetes.journal.container', normal_input, '
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        pipeline_type normalizer
      ')
      assert_equal(normal_output_t, rec['systemd']['t'])
      assert_equal(normal_output_u, rec['systemd']['u'])
      assert_equal(normal_output_k, rec['systemd']['k'])
      assert_equal('hello world', rec['message'])
      assert_equal('info', rec['level'])
      assert_equal('myhost', rec['hostname'])
      assert_equal('2017-07-27T17:27:46.216527+00:00', rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['normalizer']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['normalizer']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['normalizer']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['normalizer']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['normalizer']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['normalizer']['received_at'])
      dellist = 'log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'process a kubernetes journal record with event from eventrouter, default settings' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      input = add_event(normal_input)
      rec = emit_with_tag('kubernetes.journal.container', input, '
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        pipeline_type collector
      ')
      assert_equal(normal_output_t, rec['systemd']['t'])
      assert_equal(normal_output_u, rec['systemd']['u'])
      assert_equal(normal_output_k, rec['systemd']['k'])
      assert_equal('ADDED', rec['kubernetes']['event']['verb'])
      assert_equal('event message', rec['message'])
      assert_equal('hello world', rec['pipeline_metadata']['collector']['original_raw_message'])
      assert_equal('info', rec['level'])
      assert_equal('myhost', rec['hostname'])
      assert_equal('2017-07-27T17:23:46.216527+00:00', rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['collector']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['collector']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['collector']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['collector']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['collector']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['collector']['received_at'])
      dellist = 'log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID,event,verb'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'process a kubernetes journal record with event from eventrouter, disable event processing' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      input = add_event(normal_input)
      rec = emit_with_tag('kubernetes.journal.container', input, '
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        process_kubernetes_events false
        pipeline_type collector
      ')
      assert_equal('ADDED', rec['verb'])
      assert_equal({'message'=>'event message','metadata'=>{'creationTimestamp'=>'2017-07-27T17:23:46.216527+00:00'}}, rec['event'])
      assert_equal(normal_output_t, rec['systemd']['t'])
      assert_equal(normal_output_u, rec['systemd']['u'])
      assert_equal(normal_output_k, rec['systemd']['k'])
      assert_equal('hello world', rec['message'])
      assert_equal('info', rec['level'])
      assert_equal('myhost', rec['hostname'])
      assert_equal('2017-07-27T17:27:46.216527+00:00', rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['collector']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['collector']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['collector']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['collector']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['collector']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['collector']['received_at'])
      dellist = 'log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
      assert_nil(rec['pipeline_metadata']['collector']['original_raw_message'])
    end
    test 'process a kubernetes journal record with a bogus eventrouter event' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      input = add_event(normal_input)
      input['event'] = 'a string, not a hash'
      rec = emit_with_tag('kubernetes.journal.container', input, '
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        pipeline_type collector
      ')
      assert_equal(normal_output_t, rec['systemd']['t'])
      assert_equal(normal_output_u, rec['systemd']['u'])
      assert_equal(normal_output_k, rec['systemd']['k'])
      assert_equal('a string, not a hash', rec['event'])
      assert_equal('ADDED', rec['verb'])
      assert_equal('hello world', rec['message'])
      assert_equal('info', rec['level'])
      assert_equal('myhost', rec['hostname'])
      assert_equal('2017-07-27T17:27:46.216527+00:00', rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['collector']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['collector']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['collector']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['collector']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['collector']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['collector']['received_at'])
      dellist = 'log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'disable kubernetes journal record processing' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      rec = emit_with_tag('kubernetes.journal.container', normal_input, '
        <formatter>
          enabled false
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        pipeline_type normalizer
      ')
      assert_nil(rec['systemd'])
      notdellist = 'log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID'.split(',')
      notdellist.each{|field| assert_equal(normal_input[field], rec[field])}
    end
    test 'process a kubernetes journal record, given kubernetes.host' do
      input = normal_input.merge({})
      input['kubernetes'] = {'host' => 'k8shost'}
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      rec = emit_with_tag('kubernetes.journal.container', input, '
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        pipeline_type normalizer
      ')
      assert_equal(normal_output_t, rec['systemd']['t'])
      assert_equal(normal_output_u, rec['systemd']['u'])
      assert_equal(normal_output_k, rec['systemd']['k'])
      assert_equal('hello world', rec['message'])
      assert_equal('info', rec['level'])
      assert_equal('k8shost', rec['hostname'])
      assert_equal('2017-07-27T17:27:46.216527+00:00', rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['normalizer']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['normalizer']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['normalizer']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['normalizer']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['normalizer']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['normalizer']['received_at'])
      dellist = 'log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'process a kubernetes journal record, preserve message field' do
      input = normal_input.merge({})
      input['message'] = 'my message'
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      rec = emit_with_tag('kubernetes.journal.container', input, '
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        pipeline_type normalizer
      ')
      assert_equal(normal_output_t, rec['systemd']['t'])
      assert_equal(normal_output_u, rec['systemd']['u'])
      assert_equal(normal_output_k, rec['systemd']['k'])
      assert_equal('my message', rec['message'])
      assert_equal('info', rec['level'])
      assert_equal('myhost', rec['hostname'])
      assert_equal('2017-07-27T17:27:46.216527+00:00', rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['normalizer']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['normalizer']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['normalizer']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['normalizer']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['normalizer']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['normalizer']['received_at'])
      dellist = 'log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'process a /var/log/messages record, default settings' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      timestr = Time.at(@time).strftime('%b %d %H:%M:%S')
      expectedtime = Time.at(@time).utc.to_datetime.rfc3339(6)
      input = {"pid"=>12345,"ident"=>"service","host"=>"myhost","time"=>timestr,"message"=>"mymessage"}
      rec = emit_with_tag('system.var.log.messages', input, '
        <formatter>
          tag "system.var.log**"
          type sys_var_log
          remove_keys host,pid,ident
        </formatter>
        pipeline_type normalizer
      ')
      assert_equal(12345, rec['systemd']['t']['PID'])
      assert_equal("service", rec['systemd']['u']['SYSLOG_IDENTIFIER'])
      assert_equal('mymessage', rec['message'])
      assert_equal('myhost', rec['hostname'])
      assert_equal(expectedtime, rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['normalizer']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['normalizer']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['normalizer']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['normalizer']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['normalizer']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['normalizer']['received_at'])
      dellist = 'host,pid,ident'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'process a /var/log/messages record, future date' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      timestr = 'Dec 31 23:59:59'
      future = DateTime.strptime(timestr, '%b %d %H:%M:%S').to_time
      @time = future.to_i
      # subtract 1 from year
      expected = Time.new(future.year-1, future.month, future.day, future.hour, future.min, future.sec, future.utc_offset)
      input = {"pid"=>12345,"ident"=>"service","host"=>"myhost","time"=>timestr,"message"=>"mymessage"}
      rec = emit_with_tag('system.var.log.messages', input, '
        <formatter>
          tag "system.var.log**"
          type sys_var_log
          remove_keys host,pid,ident
        </formatter>
        pipeline_type normalizer
      ')
      assert_equal(12345, rec['systemd']['t']['PID'])
      assert_equal("service", rec['systemd']['u']['SYSLOG_IDENTIFIER'])
      assert_equal('mymessage', rec['message'])
      assert_equal('myhost', rec['hostname'])
      assert_equal(expected.utc.to_datetime.rfc3339(6), rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['normalizer']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['normalizer']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['normalizer']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['normalizer']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['normalizer']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['normalizer']['received_at'])
      dellist = 'host,pid,ident'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'process a /var/log/messages record, already has @timestamp' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      timestr = Time.at(@time).strftime('%b %d %H:%M:%S')
      input = {"pid"=>12345,"ident"=>"service","host"=>"myhost","time"=>timestr,
               "message"=>"mymessage","@timestamp"=>@timestamp_str}
      rec = emit_with_tag('system.var.log.messages', input, '
        rename_time_if_missing true
        <formatter>
          tag "system.var.log**"
          type sys_var_log
          remove_keys host,pid,ident
        </formatter>
        pipeline_type normalizer
      ')
      assert_equal(12345, rec['systemd']['t']['PID'])
      assert_equal("service", rec['systemd']['u']['SYSLOG_IDENTIFIER'])
      assert_equal('mymessage', rec['message'])
      assert_equal('myhost', rec['hostname'])
      assert_equal(@timestamp_str, rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['normalizer']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['normalizer']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['normalizer']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['normalizer']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['normalizer']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['normalizer']['received_at'])
      dellist = 'host,pid,ident'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'process a k8s json-file record, default settings' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      input = {'kubernetes'=>{'host'=>'k8shost'},'stream'=>'stderr','time'=>@timestamp_str,'log'=>'mymessage'}
      rec = emit_with_tag('kubernetes.var.log.containers.name.name_this_that_other_log', input, '
        <formatter>
          tag "kubernetes.var.log.containers**"
          type k8s_json_file
          remove_keys log,stream
        </formatter>
        pipeline_type normalizer
      ')
      assert_equal('mymessage', rec['message'])
      assert_equal('k8shost', rec['hostname'])
      assert_equal('unknown', rec['level'])
      assert_equal(@timestamp_str, rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['normalizer']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['normalizer']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['normalizer']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['normalizer']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['normalizer']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['normalizer']['received_at'])
      dellist = 'host,pid,ident'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'process a k8s json-file record with event from eventrouter, default settings' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      input = {'kubernetes'=>{'host'=>'k8shost'},'stream'=>'stderr','time'=>@timestamp_str,'log'=>'mymessage'}
      input = add_event(input)
      rec = emit_with_tag('kubernetes.var.log.containers.name.name_this_that_other_log', input, '
        <formatter>
          tag "kubernetes.var.log.containers**"
          type k8s_json_file
          remove_keys log,stream
        </formatter>
        pipeline_type collector 
      ')
      assert_equal('ADDED', rec['kubernetes']['event']['verb'])
      assert_equal('event message', rec['message'])
      assert_equal('mymessage', rec['pipeline_metadata']['collector']['original_raw_message'])
      assert_equal('unknown', rec['level'])
      assert_equal('2017-07-27T17:23:46.216527+00:00', rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['collector']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['collector']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['collector']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['collector']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['collector']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['collector']['received_at'])
      dellist = 'host,pid,ident,event,verb'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'process a k8s json-file record with event from eventrouter, per formatter setting' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      input = {'kubernetes'=>{'host'=>'k8shost'},'stream'=>'stderr','time'=>@timestamp_str,'log'=>'mymessage'}
      input = add_event(input)
      rec = emit_with_tag('kubernetes.var.log.containers.name.name_this_that_other_log', input, '
        <formatter>
          tag "kubernetes.var.log.containers**"
          type k8s_json_file
          remove_keys log,stream
          process_kubernetes_events true
        </formatter>
        pipeline_type collector
        process_kubernetes_events false
      ')
      assert_equal('ADDED', rec['kubernetes']['event']['verb'])
      assert_equal('event message', rec['message'])
      assert_equal('mymessage', rec['pipeline_metadata']['collector']['original_raw_message'])
      assert_equal('unknown', rec['level'])
      assert_equal('2017-07-27T17:23:46.216527+00:00', rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['collector']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['collector']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['collector']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['collector']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['collector']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['collector']['received_at'])
      dellist = 'host,pid,ident,event,verb'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'process a k8s json-file record with a string valued timestamp' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      now = Time.now
      input = {'kubernetes'=>{'host'=>'k8shost'},
               'stream'=>'stderr','time'=>now.to_datetime.rfc3339(9),'log'=>'mymessage'}
      rec = emit_with_tag('kubernetes.var.log.containers.name.name_this_that_other_log', input, '
        <formatter>
          tag "kubernetes.var.log.containers**"
          type k8s_json_file
          remove_keys log,stream
        </formatter>
        pipeline_type normalizer
      ')
      assert_equal('mymessage', rec['message'])
      assert_equal('k8shost', rec['hostname'])
      assert_equal('unknown', rec['level'])
      assert_equal(now.utc.to_datetime.rfc3339(6), rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['normalizer']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['normalizer']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['normalizer']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['normalizer']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['normalizer']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['normalizer']['received_at'])
      dellist = 'host,pid,ident'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'process a k8s json-file record with a string valued timestamp, alternate format' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      now = Time.now
      expectedtime = Time.parse(now.to_datetime.ctime).utc.to_datetime.rfc3339(6)
      input = {'kubernetes'=>{'host'=>'k8shost'},
               'stream'=>'stderr','time'=>now.to_datetime.ctime,'log'=>'mymessage'}
      rec = emit_with_tag('kubernetes.var.log.containers.name.name_this_that_other_log', input, '
        <formatter>
          tag "kubernetes.var.log.containers**"
          type k8s_json_file
          remove_keys log,stream
        </formatter>
        pipeline_type normalizer
      ')
      assert_equal('mymessage', rec['message'])
      assert_equal('k8shost', rec['hostname'])
      assert_equal('unknown', rec['level'])
      assert_equal(expectedtime, rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['normalizer']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['normalizer']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['normalizer']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['normalizer']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['normalizer']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['normalizer']['received_at'])
      dellist = 'host,pid,ident'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'process a k8s json-file record, already has @timestamp' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      input = {'kubernetes'=>{'host'=>'k8shost'},'@timestamp'=>@timestamp_str,
               'stream'=>'stderr','time'=>'ignored','log'=>'mymessage'}
      rec = emit_with_tag('kubernetes.var.log.containers.name.name_this_that_other_log', input, '
        rename_time_if_missing true
        <formatter>
          tag "kubernetes.var.log.containers**"
          type k8s_json_file
          remove_keys log,stream
        </formatter>
        pipeline_type normalizer
      ')
      assert_equal('mymessage', rec['message'])
      assert_equal('k8shost', rec['hostname'])
      assert_equal('unknown', rec['level'])
      assert_equal(@timestamp_str, rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['normalizer']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['normalizer']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['normalizer']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['normalizer']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['normalizer']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['normalizer']['received_at'])
      dellist = 'host,pid,ident'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'process a k8s json-file record, no time field' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      input = {'kubernetes'=>{'host'=>'k8shost'},
               'stream'=>'stderr','log'=>'mymessage'}
      rec = emit_with_tag('kubernetes.var.log.containers.name.name_this_that_other_log', input, '
        <formatter>
          tag "kubernetes.var.log.containers**"
          type k8s_json_file
          remove_keys log,stream
        </formatter>
        pipeline_type normalizer
      ')
      assert_equal('mymessage', rec['message'])
      assert_equal('k8shost', rec['hostname'])
      assert_equal('unknown', rec['level'])
      assert_equal(Time.at(@time).utc.to_datetime.rfc3339(6), rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['normalizer']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['normalizer']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['normalizer']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['normalizer']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['normalizer']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['normalizer']['received_at'])
      dellist = 'host,pid,ident'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'process a k8s json-file record, stdout stream' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      input = {'kubernetes'=>{'host'=>'k8shost'},'stream'=>'stdout','time'=>@timestamp_str,'log'=>'mymessage'}
      rec = emit_with_tag('kubernetes.var.log.containers.name.name_this_that_other_log', input, '
        <formatter>
          tag "kubernetes.var.log.containers**"
          type k8s_json_file
          remove_keys log,stream
        </formatter>
        pipeline_type normalizer
      ')
      assert_equal('mymessage', rec['message'])
      assert_equal('k8shost', rec['hostname'])
      assert_equal('unknown', rec['level'])
      assert_equal(@timestamp_str, rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['normalizer']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['normalizer']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['normalizer']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['normalizer']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['normalizer']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['normalizer']['received_at'])
      dellist = 'host,pid,ident'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'process a k8s json-file record, existing level field' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      input = {'kubernetes'=>{'host'=>'k8shost'},'stream'=>'stderr','time'=>@timestamp_str,'log'=>'mymessage','level'=>0}
      rec = emit_with_tag('kubernetes.var.log.containers.name.name_this_that_other_log', input, '
        <formatter>
          tag "kubernetes.var.log.containers**"
          type k8s_json_file
          remove_keys log,stream
        </formatter>
        pipeline_type normalizer
      ')
      assert_equal('mymessage', rec['message'])
      assert_equal('k8shost', rec['hostname'])
      assert_equal('0', rec['level'])
      assert_equal(@timestamp_str, rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['normalizer']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['normalizer']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['normalizer']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['normalizer']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['normalizer']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['normalizer']['received_at'])
      dellist = 'host,pid,ident'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    test 'process a k8s json-file record, already normalized existing level field' do
      ENV['IPADDR4'] = '127.0.0.1'
      ENV['IPADDR6'] = '::1'
      ENV['FLUENTD_VERSION'] = 'fversion'
      ENV['DATA_VERSION'] = 'dversion'
      input = {'kubernetes'=>{'host'=>'k8shost'},'stream'=>'stderr','time'=>@timestamp_str,'log'=>'mymessage','level'=>'debug'}
      rec = emit_with_tag('kubernetes.var.log.containers.name.name_this_that_other_log', input, '
        <formatter>
          tag "kubernetes.var.log.containers**"
          type k8s_json_file
          remove_keys log,stream
        </formatter>
        pipeline_type normalizer
      ')
      assert_equal('mymessage', rec['message'])
      assert_equal('k8shost', rec['hostname'])
      assert_equal('debug', rec['level'])
      assert_equal(@timestamp_str, rec['@timestamp'])
      assert_equal('127.0.0.1', rec['pipeline_metadata']['normalizer']['ipaddr4'])
      assert_equal('::1', rec['pipeline_metadata']['normalizer']['ipaddr6'])
      assert_equal('fluent-plugin-systemd', rec['pipeline_metadata']['normalizer']['inputname'])
      assert_equal('fluentd', rec['pipeline_metadata']['normalizer']['name'])
      assert_equal('fversion dversion', rec['pipeline_metadata']['normalizer']['version'])
      assert_equal(@timestamp_str, rec['pipeline_metadata']['normalizer']['received_at'])
      dellist = 'host,pid,ident'.split(',')
      dellist.each{|field| assert_nil(rec[field])}
    end
    # tests for elasticsearch index functionality
    test 'construct an operations index prefix' do
      rec = emit_with_tag('journal.system', normal_input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <elasticsearch_index_name>
          tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
          name_type operations_prefix
        </elasticsearch_index_name>
        <elasticsearch_index_name>
          tag "**"
          name_type project_prefix
        </elasticsearch_index_name>
      ')
      assert_equal('.operations', rec['viaq_index_prefix'])
    end
    test 'construct an operations index prefix with named field' do
      rec = emit_with_tag('journal.system', normal_input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <elasticsearch_index_name>
          tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
          name_type operations_prefix
        </elasticsearch_index_name>
        <elasticsearch_index_name>
          tag "**"
          name_type project_prefix
        </elasticsearch_index_name>
        elasticsearch_index_prefix_field my_index_prefix
      ')
      assert_equal('.operations', rec['my_index_prefix'])
    end
    test 'construct a static index prefix with named field' do
      rec = emit_with_tag('journal.system', normal_input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <elasticsearch_index_name>
          tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
          name_type static
          static_index_name foo-bar
        </elasticsearch_index_name>
        <elasticsearch_index_name>
          tag "**"
          name_type project_prefix
        </elasticsearch_index_name>
        elasticsearch_index_prefix_field my_index_prefix
      ')
      assert_equal('foo-bar', rec['my_index_prefix'])
    end
    test 'construct an operations index name with named field' do
      rec = emit_with_tag('journal.system', normal_input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <elasticsearch_index_name>
          tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
          name_type operations_full
        </elasticsearch_index_name>
        <elasticsearch_index_name>
          tag "**"
          name_type project_full
        </elasticsearch_index_name>
        elasticsearch_index_name_field my_index_name
      ')
      assert_equal('.operations.2017.07.27', rec['my_index_name'])
    end
    test 'disable operations index name' do
      rec = emit_with_tag('journal.system', normal_input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <elasticsearch_index_name>
          enabled false
          tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
          name_type operations_full
        </elasticsearch_index_name>
        <elasticsearch_index_name>
          tag "**"
          name_type project_full
        </elasticsearch_index_name>
      ')
      assert_nil(rec['viaq_index_name'])
    end
    test 'log error if missing kubernetes field' do
      rec = emit_with_tag('kubernetes.journal.container.something', normal_input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <elasticsearch_index_name>
          tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
          name_type operations_prefix
        </elasticsearch_index_name>
        <elasticsearch_index_name>
          tag "**"
          name_type project_prefix
        </elasticsearch_index_name>
        elasticsearch_index_prefix_field my_index_prefix
      ')
      assert_match /record is missing kubernetes field/, @dlog.logs[0]
      assert_equal('.orphaned', rec['my_index_prefix'])
    end
    test 'log error if missing kubernetes.namespace_name field' do
      input = normal_input.merge({})
      input['kubernetes'] = 'junk'
      rec = emit_with_tag('kubernetes.journal.container.something', input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
          elasticsearch_index_name_field my_index_name
        </formatter>
        <elasticsearch_index_name>
          tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
          name_type operations_prefix
        </elasticsearch_index_name>
        <elasticsearch_index_name>
          tag "**"
          name_type project_prefix
        </elasticsearch_index_name>
        elasticsearch_index_prefix_field my_index_prefix
      ')
      assert_match /record is missing kubernetes.namespace_name field/, @dlog.logs[0]
      assert_equal('.orphaned', rec['my_index_prefix'])
    end
    test 'log error if missing kubernetes.namespace_id field' do
      input = normal_input.merge({})
      input['kubernetes'] = {'namespace_name'=>'junk'}
      rec = emit_with_tag('kubernetes.journal.container.something', input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <elasticsearch_index_name>
          tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
          name_type operations_prefix
        </elasticsearch_index_name>
        <elasticsearch_index_name>
          tag "**"
          name_type project_prefix
        </elasticsearch_index_name>
        elasticsearch_index_prefix_field my_index_prefix
      ')
      assert_match /record is missing kubernetes.namespace_id field/, @dlog.logs[0]
      assert_equal('.orphaned', rec['my_index_prefix'])
    end
    test 'construct a kubernetes index prefix' do
      input = normal_input.merge({})
      input['kubernetes'] = {'namespace_name'=>'name', 'namespace_id'=>'uuid'}
      rec = emit_with_tag('kubernetes.journal.container.something', input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <elasticsearch_index_name>
          tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
          name_type operations_prefix
        </elasticsearch_index_name>
        <elasticsearch_index_name>
          tag "**"
          name_type project_prefix
        </elasticsearch_index_name>
      ')
      assert_equal('project.name.uuid', rec['viaq_index_prefix'])
    end
    test 'construct a kubernetes index prefix with named field' do
      input = normal_input.merge({})
      input['kubernetes'] = {'namespace_name'=>'name', 'namespace_id'=>'uuid'}
      rec = emit_with_tag('kubernetes.journal.container.something', input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <elasticsearch_index_name>
          tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
          name_type operations_prefix
        </elasticsearch_index_name>
        <elasticsearch_index_name>
          tag "**"
          name_type project_prefix
        </elasticsearch_index_name>
        elasticsearch_index_prefix_field my_index_prefix
      ')
      assert_equal('project.name.uuid', rec['my_index_prefix'])
    end
    test 'construct a kubernetes index name with named field' do
      input = normal_input.merge({})
      input['kubernetes'] = {'namespace_name'=>'name', 'namespace_id'=>'uuid'}
      rec = emit_with_tag('kubernetes.journal.container.something', input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <elasticsearch_index_name>
          tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
          name_type operations_full
        </elasticsearch_index_name>
        <elasticsearch_index_name>
          tag "**"
          name_type project_full
        </elasticsearch_index_name>
        elasticsearch_index_name_field my_index_name
      ')
      assert_equal('project.name.uuid.2017.07.27', rec['my_index_name'])
    end
    test 'disable kubernetes index names but allow operations index names' do
      input = normal_input.merge({})
      input['kubernetes'] = {'namespace_name'=>'name', 'namespace_id'=>'uuid'}
      rec = emit_with_tag('kubernetes.journal.container.something', input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <elasticsearch_index_name>
          tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
          name_type operations_full
        </elasticsearch_index_name>
        <elasticsearch_index_name>
          enabled false
          tag "**"
          name_type project_full
        </elasticsearch_index_name>
      ')
      assert_nil(rec['viaq_index_name'])
      rec = emit_with_tag('journal.system.something', normal_input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <elasticsearch_index_name>
          tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
          name_type operations_full
        </elasticsearch_index_name>
        <elasticsearch_index_name>
          enabled false
          tag "**"
          name_type project_full
        </elasticsearch_index_name>
      ')
      assert_equal('.operations.2017.07.27', rec['viaq_index_name'])
    end
    test 'construct an operations index name from a kubernetes record in an operations namespace' do
      input = normal_input.merge({})
      input['kubernetes'] = {'namespace_name'=>'default', 'namespace_id'=>'uuid'}
      rec = emit_with_tag('kubernetes.journal.container._default_', input, '
        <formatter>
          tag "journal.system**"
          type sys_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <formatter>
          tag "kubernetes.journal.container**"
          type k8s_journal
          remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
        </formatter>
        <elasticsearch_index_name>
          tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
          name_type operations_full
        </elasticsearch_index_name>
        <elasticsearch_index_name>
          tag "**"
          name_type project_full
        </elasticsearch_index_name>
      ')
      assert_equal('.operations.2017.07.27', rec['viaq_index_name'])
    end
    # level field processing
    test 'see if existing level is preserved for journald log' do
      rec = emit_with_tag('journal.system', {'a'=>'b', 'level'=>'this is my level'}, '
        <formatter>
          tag "journal.system**"
          type sys_journal
        </formatter>
      ')
      assert_equal('b', rec['a'])
      assert_equal('this is my level', rec['level'])
    end
    test 'see if existing level is preserved and overrides PRIORITY' do
      rec = emit_with_tag('journal.system', {'a'=>'b', 'PRIORITY'=>'3', 'level'=>'this is my level'}, '
        <formatter>
          tag "journal.system**"
          type sys_journal
        </formatter>
      ')
      assert_equal('b', rec['a'])
      assert_equal('this is my level', rec['level'])
    end
    test 'see if existing level is preserved and converted to string' do
      rec = emit_with_tag('journal.system', {'a'=>'b', 'level'=>1}, '
        <formatter>
          tag "journal.system**"
          type sys_journal
        </formatter>
      ')
      assert_equal('b', rec['a'])
      assert_equal('1', rec['level'])
    end
    test 'see if existing level is preserved and converted to string with an odd type' do
      rec = emit_with_tag('journal.system', {'a'=>'b', 'level'=>{}}, '
        <formatter>
          tag "journal.system**"
          type sys_journal
        </formatter>
      ')
      assert_equal('b', rec['a'])
      assert_equal('{}', rec['level'])
    end
    test 'see if existing level is normalized to canonical form' do
      rec = emit_with_tag('journal.system', {'a'=>'b', 'level'=>'CRITICAL'}, '
        <formatter>
          tag "journal.system**"
          type sys_journal
        </formatter>
      ')
      assert_equal('b', rec['a'])
      assert_equal('crit', rec['level'])
    end
    test 'see if existing level already normalized is preserved' do
      rec = emit_with_tag('journal.system', {'a'=>'b', 'level'=>'crit'}, '
        <formatter>
          tag "journal.system**"
          type sys_journal
        </formatter>
      ')
      assert_equal('b', rec['a'])
      assert_equal('crit', rec['level'])
    end
  end

  sub_test_case 'undefined handling' do
    def emit_with_tag(tag, msg={}, conf='')
      d = create_driver(conf)
      d.run {
        d.emit_with_tag(tag, msg, @time)
      }.filtered.instance_variable_get(:@record_array)[0]
    end
    test 'see if undefined fields are normalized to string and kept at top level' do
      rec = emit_with_tag('tag', {'a'=>'b','c'=>404,'d'=>{'e'=>'f'},'g'=>[1, 2, 3]}, '
        default_keep_fields x,y,z,time
        undefined_to_string true
      ')
      assert_equal('b', rec['a'])
      assert_equal('404', rec['c'])
      assert_equal('{"e":"f"}', rec['d'])
      assert_equal('[1,2,3]', rec['g'])
    end
    test 'see if undefined fields with dots in the name are replaced and undefined fields are normalized to string and kept at top level' do
      rec = emit_with_tag('tag', {'a'=>'b','c'=>404,'d'=>{'e'=>'f'},'g'=>[1, 2, 3],'h.i.j'=>1}, '
        default_keep_fields x,y,z,time
        undefined_to_string true
        undefined_dot_replace_char _
      ')
      assert_equal('b', rec['a'])
      assert_equal('404', rec['c'])
      assert_equal('{"e":"f"}', rec['d'])
      assert_equal('[1,2,3]', rec['g'])
      assert_equal('1', rec['h_i_j'])
      assert_nil(rec['h.i.j'])
    end
    test 'check undefined fields with dots, undefined fields are normalized to string and kept in undefined container' do
      rec = emit_with_tag('tag', {'a'=>'b','c'=>404,'d'=>{'e'=>'f'},'g'=>[1, 2, 3],'h.i.j'=>1}, '
        default_keep_fields x,y,z,time
        undefined_to_string true
        undefined_dot_replace_char _
        use_undefined true
      ')
      assert_equal('b', rec['undefined']['a'])
      assert_equal('404', rec['undefined']['c'])
      assert_equal('{"e":"f"}', rec['undefined']['d'])
      assert_equal('[1,2,3]', rec['undefined']['g'])
      assert_equal('1', rec['undefined']['h_i_j'])
      assert_nil(rec['h.i.j'])
      assert_nil(rec['undefined']['h.i.j'])
    end
    test 'check too many undefined fields stored as undefined JSON blob' do
      require 'json'
      input = {'a'=>'b','c'=>404,'d'=>{'e'=>'f'},'g'=>[1, 2, 3],'h.i.j'=>1}
      output = JSON.dump(input)
      rec = emit_with_tag('tag', input, '
        default_keep_fields x,y,z,time,pipeline_metadata
        undefined_to_string true
        undefined_dot_replace_char _
        use_undefined true
        undefined_max_num_fields 0
      ')
      assert_equal(output, rec['undefined'])
      assert_nil(rec['a'])
      assert_nil(rec['c'])
      assert_nil(rec['d'])
      assert_nil(rec['g'])
      assert_nil(rec['h.i.j'])
    end
  end
end
