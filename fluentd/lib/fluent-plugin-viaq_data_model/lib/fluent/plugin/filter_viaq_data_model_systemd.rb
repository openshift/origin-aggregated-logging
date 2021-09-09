#
# Fluentd ViaQ data model Filter Plugin
#
# Copyright 2017 Red Hat, Inc.
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
require 'time'
require 'date'

module ViaqDataModelFilterSystemd
  # map of journal fields to viaq data model field
  JOURNAL_FIELD_MAP_SYSTEMD_T = {
    "_AUDIT_LOGINUID"        => "AUDIT_LOGINUID",
    "_AUDIT_SESSION"         => "AUDIT_SESSION",
    "_BOOT_ID"               => "BOOT_ID",
    "_CAP_EFFECTIVE"         => "CAP_EFFECTIVE",
    "_CMDLINE"               => "CMDLINE",
    "_COMM"                  => "COMM",
    "_EXE"                   => "EXE",
    "_GID"                   => "GID",
    "_LINE_BREAK"            => "LINE_BREAK",
    "_MACHINE_ID"            => "MACHINE_ID",
    "_PID"                   => "PID",
    "_SELINUX_CONTEXT"       => "SELINUX_CONTEXT",
    "_STREAM_ID"             => "STREAM_ID",
    "_SYSTEMD_CGROUP"        => "SYSTEMD_CGROUP",
    "_SYSTEMD_INVOCATION_ID" => "SYSTEMD_INVOCATION_ID",
    "_SYSTEMD_OWNER_UID"     => "SYSTEMD_OWNER_UID",
    "_SYSTEMD_SESSION"       => "SYSTEMD_SESSION",
    "_SYSTEMD_SLICE"         => "SYSTEMD_SLICE",
    "_SYSTEMD_UNIT"          => "SYSTEMD_UNIT",
    "_SYSTEMD_USER_UNIT"     => "SYSTEMD_USER_UNIT",
    "_TRANSPORT"             => "TRANSPORT",
    "_UID"                   => "UID"
  }

  JOURNAL_FIELD_MAP_SYSTEMD_U = {
    "CODE_FILE"         => "CODE_FILE",
    "CODE_FUNCTION"     => "CODE_FUNCTION",
    "CODE_LINE"         => "CODE_LINE",
    "ERRNO"             => "ERRNO",
    "MESSAGE_ID"        => "MESSAGE_ID",
    "RESULT"            => "RESULT",
    "UNIT"              => "UNIT",
    "SYSLOG_FACILITY"   => "SYSLOG_FACILITY",
    "SYSLOG_IDENTIFIER" => "SYSLOG_IDENTIFIER",
    "SYSLOG_PID"        => "SYSLOG_PID"
  }

  JOURNAL_FIELD_MAP_SYSTEMD_K = {
    "_KERNEL_DEVICE"    => "KERNEL_DEVICE",
    "_KERNEL_SUBSYSTEM" => "KERNEL_SUBSYSTEM",
    "_UDEV_SYSNAME"     => "UDEV_SYSNAME",
    "_UDEV_DEVNODE"     => "UDEV_DEVNODE",
    "_UDEV_DEVLINK"     => "UDEV_DEVLINK",
  }

  JOURNAL_TIME_FIELDS = ['_SOURCE_REALTIME_TIMESTAMP', '__REALTIME_TIMESTAMP']

  def process_journal_fields(tag, time, record, fmtr)
    systemd_t = {}
    JOURNAL_FIELD_MAP_SYSTEMD_T.each do |jkey, key|
      if record.key?(jkey)
        systemd_t[key] = record[jkey]
      end
    end
    systemd_u = {}
    JOURNAL_FIELD_MAP_SYSTEMD_U.each do |jkey, key|
      if record.key?(jkey)
        systemd_u[key] = record[jkey]
      end
    end
    systemd_k = {}
    JOURNAL_FIELD_MAP_SYSTEMD_K.each do |jkey, key|
      if record.key?(jkey)
        systemd_k[key] = record[jkey]
      end
    end
    unless systemd_t.empty?
      (record['systemd'] ||= {})['t'] = systemd_t
    end
    unless systemd_u.empty?
      (record['systemd'] ||= {})['u'] = systemd_u
    end
    unless systemd_k.empty?
      (record['systemd'] ||= {})['k'] = systemd_k
    end
    normalize_level!(record, record['PRIORITY'])
    JOURNAL_TIME_FIELDS.each do |field|
      if (val = record[field])
        vali = val.to_i
        record['time'] = Time.at(vali / 1000000, vali % 1000000).utc.to_datetime.rfc3339(6)
        break
      end
    end
    case fmtr.type
    when :sys_journal
      record['message'] = record['MESSAGE']
      if record['_HOSTNAME'].eql?('localhost') && @docker_hostname
        record['hostname'] = @docker_hostname
      else
        record['hostname'] = record['_HOSTNAME']
      end
      # system, non-kubernetes containers
      docker = {}
      if record.key?('CONTAINER_ID_FULL')
        docker['container_id'] = record['CONTAINER_ID_FULL']
      end
      if record.key?('CONTAINER_ID')
        docker['container_id_short'] = record['CONTAINER_ID']
      end
      if record.key?('CONTAINER_NAME')
        docker['container_name'] = record['CONTAINER_NAME']
      end
      unless docker.empty?
        record['docker'] = record['docker'] ? record['docker'].merge(docker) : docker
      end
    when :k8s_journal
      record['message'] = record['message'] || record['MESSAGE'] || record['log']
      if record.key?('kubernetes') && record['kubernetes'].respond_to?(:fetch) && \
         (k8shost = record['kubernetes'].fetch('host', nil))
        record['hostname'] = k8shost
      elsif @docker_hostname
        record['hostname'] = @docker_hostname
      else
        record['hostname'] = record['_HOSTNAME']
      end
      transform_eventrouter(tag, record, fmtr)
    end
  end
end
