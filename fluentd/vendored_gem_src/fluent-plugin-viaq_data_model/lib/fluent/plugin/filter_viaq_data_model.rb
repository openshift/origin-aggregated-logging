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
require 'json'

require 'fluent/filter'
require 'fluent/log'
require 'fluent/match'

require_relative 'filter_viaq_data_model_systemd'

begin
  ViaqMatchClass = Fluent::Match
rescue
  # Fluent::Match not provided with 0.14
  class ViaqMatchClass
    def initialize(pattern_str, unused)
      patterns = pattern_str.split(/\s+/).map {|str|
        Fluent::MatchPattern.create(str)
      }
      if patterns.length == 1
        @pattern = patterns[0]
      else
        @pattern = Fluent::OrMatchPattern.new(patterns)
      end
    end
    def match(tag)
      @pattern.match(tag)
    end
    def to_s
      "#{@pattern}"
    end
  end
end

module Fluent
  class ViaqDataModelFilter < Filter
    include ViaqDataModelFilterSystemd
    Fluent::Plugin.register_filter('viaq_data_model', self)

    desc 'Default list of comma-delimited fields to keep in each record'
    config_param :default_keep_fields, default: [] do |val|
      val.split(',')
    end

    desc 'Optional extra list of comma-delimited fields to keep in each record'
    config_param :extra_keep_fields, default: [] do |val|
      val.split(',')
    end

    # The kibana pod emits log records with an empty message field
    # we want to preserve these empty messages
    desc 'List of fields to keep as empty fields - also added to extra_keep_fields'
    config_param :keep_empty_fields, default: ['message'] do |val|
      val.split(',')
    end

    desc 'Use "undefined" field to store fields not in above lists'
    config_param :use_undefined, :bool, default: false

    desc 'Name of undefined field to store fields not in above lists if use_undefined is true'
    config_param :undefined_name, :string, default: 'undefined'

    desc 'Normalize undefined fields to string - highly recommended to use true'
    config_param :undefined_to_string, :bool, default: false

    DOT_REPLACE_CHAR_UNUSED = 'UNUSED'
    desc 'Undefined dot replace char - highly recommended to use _'
    config_param :undefined_dot_replace_char, :string, default: DOT_REPLACE_CHAR_UNUSED
  
    NUM_FIELDS_UNLIMITED = -1
    desc 'Maximum number of undefined fields - highly recommended to use 500 or less'
    config_param :undefined_max_num_fields, :integer, default: NUM_FIELDS_UNLIMITED

    # we can't directly add a field called @timestamp in a record_transform
    # filter because the '@' is special to fluentd
    desc 'Rename timestamp field to Elasticsearch compatible name'
    config_param :rename_time, :bool, default: true

    desc 'Rename timestamp field to Elasticsearch compatible name only if the destination field does not already exist'
    config_param :rename_time_if_missing, :bool, default: false

    desc 'Name of source timestamp field'
    config_param :src_time_name, :string, default: 'time'

    desc 'Name of destination timestamp field'
    config_param :dest_time_name, :string, default: '@timestamp'

    # <formatter>
    #   type sys_journal
    #   tag "journal.system**"
    #   remove_keys log,stream,MESSAGE,_SOURCE_REALTIME_TIMESTAMP,__REALTIME_TIMESTAMP,CONTAINER_ID,CONTAINER_ID_FULL,CONTAINER_NAME,PRIORITY,_BOOT_ID,_CAP_EFFECTIVE,_CMDLINE,_COMM,_EXE,_GID,_HOSTNAME,_MACHINE_ID,_PID,_SELINUX_CONTEXT,_SYSTEMD_CGROUP,_SYSTEMD_SLICE,_SYSTEMD_UNIT,_TRANSPORT,_UID,_AUDIT_LOGINUID,_AUDIT_SESSION,_SYSTEMD_OWNER_UID,_SYSTEMD_SESSION,_SYSTEMD_USER_UNIT,CODE_FILE,CODE_FUNCTION,CODE_LINE,ERRNO,MESSAGE_ID,RESULT,UNIT,_KERNEL_DEVICE,_KERNEL_SUBSYSTEM,_UDEV_SYSNAME,_UDEV_DEVNODE,_UDEV_DEVLINK,SYSLOG_FACILITY,SYSLOG_IDENTIFIER,SYSLOG_PID
    # </formatter>
    # formatters will be processed in the order specified, so make sure more specific matches
    # come before more general matches
    desc 'Formatters for common data model, for well known record types'
    config_section :formatter, param_name: :formatters do
      desc 'is this formatter enabled?'
      config_param :enabled, :bool, default: true
      desc 'one of the well known formatter types'
      config_param :type, :enum, list: [:sys_journal, :k8s_journal, :sys_var_log, :k8s_json_file]
      desc 'process records with this tag pattern'
      config_param :tag, :string
      desc 'remove these keys from the record - same as record_transformer "remove_keys" field'
      config_param :remove_keys, :string, default: nil
    end

    desc 'Which part of the pipeline is this - collector, normalizer, etc. for pipeline_metadata'
    config_param :pipeline_type, :enum, list: [:collector, :normalizer], default: :collector

    # e.g.
    # <elasticsearch_index_name>
    #   tag "journal.system** system.var.log** **_default_** **_openshift_** **_openshift-infra_** mux.ops"
    #   name_type operations_full
    # </elasticsearch_index_name>
    # <elasticsearch_index_name>
    #   tag "**"
    #   name_type project_full
    # </elasticsearch_index_name>
    # operations_full - ".operations.YYYY.MM.DD"
    # operations_prefix - ".operations"
    # project_full - "project.${kubernetes.namespace_name}.${kubernetes.namespace_id}.YYYY.MM.DD"
    # project_prefix - "project.${kubernetes.namespace_name}.${kubernetes.namespace_id}"
    # index names will be processed in the order specified, so make sure more specific matches
    # come before more general matches e.g. make sure tag "**" is last
    desc 'Construct Elasticsearch index names or prefixes based on the matching tags pattern and type'
    config_section :elasticsearch_index_name, param_name: :elasticsearch_index_names do
      desc 'is this index name enabled?'
      config_param :enabled, :bool, default: true
      desc 'create index names for records with this tag pattern'
      config_param :tag, :string
      desc 'type of index name to create'
      config_param :name_type, :enum, list: [:operations_full, :project_full, :operations_prefix, :project_prefix]
    end
    desc 'Store the Elasticsearch index name in this field'
    config_param :elasticsearch_index_name_field, :string, default: 'viaq_index_name'
    desc 'Store the Elasticsearch index prefix in this field'
    config_param :elasticsearch_index_prefix_field, :string, default: 'viaq_index_prefix'
    desc 'Optionally turn off processing of kubernetes events'
    config_param :process_kubernetes_events, :bool, default: true

    config_param :orphaned_namespace_name, :string, default: '.orphaned'

    def configure(conf)
      super
      @keep_fields = {}
      @default_keep_fields.each{|xx| @keep_fields[xx] = true}
      @extra_keep_fields.each{|xx| @keep_fields[xx] = true}
      @keep_empty_fields_hash = {}
      @keep_empty_fields.each do |xx|
        @keep_empty_fields_hash[xx] = true
        @keep_fields[xx] = true
      end
      if @use_undefined && @keep_fields.key?(@undefined_name)
        raise Fluent::ConfigError, "Do not put [#{@undefined_name}] in default_keep_fields or extra_keep_fields"
      end
      if (@rename_time || @rename_time_if_not_exist) && @use_undefined && !@keep_fields.key?(@src_time_name)
        raise Fluent::ConfigError, "Field [#{@src_time_name}] must be listed in default_keep_fields or extra_keep_fields"
      end
      @undefined_dot_replace_char = nil if @undefined_dot_replace_char == DOT_REPLACE_CHAR_UNUSED
      if @formatters
        @formatters.each do |fmtr|
          matcher = ViaqMatchClass.new(fmtr.tag, nil)
          fmtr.instance_eval{ @params[:matcher] = matcher }
          fmtr.instance_eval{ @params[:fmtr_type] = fmtr.type }
          if fmtr.remove_keys
            fmtr.instance_eval{ @params[:fmtr_remove_keys] = fmtr.remove_keys.split(',') }
          else
            fmtr.instance_eval{ @params[:fmtr_remove_keys] = nil }
          end
          case fmtr.type
          when :sys_journal, :k8s_journal
            fmtr_func = method(:process_journal_fields)
          when :sys_var_log
            fmtr_func = method(:process_sys_var_log_fields)
          when :k8s_json_file
            fmtr_func = method(:process_k8s_json_file_fields)
          end
          fmtr.instance_eval{ @params[:fmtr_func] = fmtr_func }
        end
        @formatter_cache = {}
        @formatter_cache_nomatch = {}
      end
      begin
        @docker_hostname = File.open('/etc/docker-hostname') { |f| f.readline }.rstrip
      rescue
        @docker_hostname = nil
      end
      @ipaddr4 = ENV['IPADDR4'] || '127.0.0.1'
      @ipaddr6 = ENV['IPADDR6'] || '::1'
      @pipeline_version = (ENV['FLUENTD_VERSION'] || 'unknown fluentd version') + ' ' + (ENV['DATA_VERSION'] || 'unknown data version')
      # create the elasticsearch index name tag matchers
      unless @elasticsearch_index_names.empty?
        @elasticsearch_index_names.each do |ein|
          matcher = ViaqMatchClass.new(ein.tag, nil)
          ein.instance_eval{ @params[:matcher] = matcher }
        end
      end
    end

    def start
      super
    end

    def shutdown
      super
    end

    # if thing doesn't respond to empty? then assume it isn't empty e.g.
    # 0.respond_to?(:empty?) == false - the FixNum 0 is not empty
    def isempty(thing)
      thing.respond_to?(:empty?) && thing.empty?
    end

    # recursively delete empty fields and empty lists/hashes from thing
    def delempty(thing)
      if thing.respond_to?(:delete_if)
        if thing.kind_of? Hash
          thing.delete_if{|k,v| v.nil? || isempty(delempty(v)) || isempty(v)}
        else # assume single element iterable
          thing.delete_if{|elem| elem.nil? || isempty(delempty(elem)) || isempty(elem)}
        end
      end
      thing
    end

    # https://github.com/ViaQ/elasticsearch-templates/blob/master/namespaces/_default_.yml#L63
    NORMAL_LEVELS = {
      'emerg'    => 'emerg',
      'panic'    => 'emerg',
      'alert'    => 'alert',
      'crit'     => 'crit',
      'critical' => 'crit',
      'err'      => 'err',
      'error'    => 'err',
      'warning'  => 'warning',
      'warn'     => 'warning',
      'notice'   => 'notice',
      'info'     => 'info',
      'debug'    => 'debug',
      'trace'    => 'trace',
      'unknown'  => 'unknown',
    }
    # numeric levels for the PRIORITY field
    PRIORITY_LEVELS = {
      0 => 'emerg',
      1 => 'alert',
      2 => 'crit',
      3 => 'err',
      4 => 'warning',
      5 => 'notice',
      6 => 'info',
      7 => 'debug',
      8 => 'trace',
      9 => 'unknown',
      '0' => 'emerg',
      '1' => 'alert',
      '2' => 'crit',
      '3' => 'err',
      '4' => 'warning',
      '5' => 'notice',
      '6' => 'info',
      '7' => 'debug',
      '8' => 'trace',
      '9' => 'unknown',
    }
    def normalize_level(level, newlevel, stream=nil, priority=nil)
      # if the record already has a level field, and it looks like one of our well
      # known values, convert it to the canonical normalized form - otherwise,
      # preserve the value in string format
      retlevel = nil
      if !level.nil?
        unless (retlevel = NORMAL_LEVELS[level]) ||
               (level.respond_to?(:downcase) && (retlevel = NORMAL_LEVELS[level.downcase]))
          retlevel = level.to_s # don't know what it is - just convert to string
        end
      elsif stream == 'stdout'
        retlevel = 'info'
      elsif stream == 'stderr'
        retlevel = 'err'
      elsif !priority.nil?
        retlevel = PRIORITY_LEVELS[priority]
      else
        retlevel = NORMAL_LEVELS[newlevel]
      end
      retlevel || 'unknown'
    end

    def process_sys_var_log_fields(tag, time, record, fmtr_type = nil)
      record['systemd'] = {"t" => {"PID" => record['pid']}, "u" => {"SYSLOG_IDENTIFIER" => record['ident']}}
      if record[@dest_time_name].nil? # e.g. already has @timestamp
        # handle the case where the time reported in /var/log/messages is for a previous year
        timeobj = Time.at(time)
        if timeobj > Time.now
          timeobj = Time.new((timeobj.year - 1), timeobj.month, timeobj.day, timeobj.hour, timeobj.min, timeobj.sec, timeobj.utc_offset)
        end
        record['time'] = timeobj.utc.to_datetime.rfc3339(6)
      end
      if record['host'].eql?('localhost') && @docker_hostname
        record['hostname'] = @docker_hostname
      else
        record['hostname'] = record['host']
      end
    end

    def process_k8s_json_file_fields(tag, time, record, fmtr_type = nil)
      record['message'] = record['message'] || record['log']
      record['level'] = normalize_level(record['level'], nil, record['stream'])
      if record.key?('kubernetes') && record['kubernetes'].respond_to?(:fetch) && \
         (k8shost = record['kubernetes'].fetch('host', nil))
        record['hostname'] = k8shost
      elsif @docker_hostname
        record['hostname'] = @docker_hostname
      end
      if record[@dest_time_name].nil? # e.g. already has @timestamp
        unless record['time'].nil?
          # convert from string - parses a wide variety of formats
          rectime = Time.parse(record['time'])
        else
          # convert from time_t
          rectime = Time.at(time)
        end
        record['time'] = rectime.utc.to_datetime.rfc3339(6)
      end
      transform_eventrouter(tag, record)
    end

    def check_for_match_and_format(tag, time, record)
      return unless @formatters
      return if @formatter_cache_nomatch[tag]
      fmtr = @formatter_cache[tag]
      unless fmtr
        idx = @formatters.index{|fmtr| fmtr.matcher.match(tag)}
        if idx && (fmtr = @formatters[idx]).enabled
          @formatter_cache[tag] = fmtr
        else
          @formatter_cache_nomatch[tag] = true
          return
        end
      end
      fmtr.fmtr_func.call(tag, time, record, fmtr.fmtr_type)

      if record[@dest_time_name].nil? && record['time'].nil?
        record['time'] = Time.at(time).utc.to_datetime.rfc3339(6)
      end

      if fmtr.fmtr_remove_keys
        fmtr.fmtr_remove_keys.each{|k| record.delete(k)}
      end
    end

    def add_pipeline_metadata (tag, time, record)
      record['pipeline_metadata'] = {} unless record.key?('pipeline_metadata')
      pipeline_type = @pipeline_type.to_s
      # this will catch the case where pipeline_type doesn't exist, or is not a Hash
      record['pipeline_metadata'][pipeline_type] = {} unless record['pipeline_metadata'][pipeline_type].respond_to?(:fetch)
      record['pipeline_metadata'][pipeline_type]['ipaddr4'] = @ipaddr4
      record['pipeline_metadata'][pipeline_type]['ipaddr6'] = @ipaddr6
      record['pipeline_metadata'][pipeline_type]['inputname'] = 'fluent-plugin-systemd'
      record['pipeline_metadata'][pipeline_type]['name'] = 'fluentd'
      record['pipeline_metadata'][pipeline_type]['received_at'] = Time.now.utc.to_datetime.rfc3339(6)
      record['pipeline_metadata'][pipeline_type]['version'] = @pipeline_version
    end

    def add_elasticsearch_index_name_field(tag, time, record)
      found = false
      @elasticsearch_index_names.each do |ein|
        if ein.matcher.match(tag)
          found = true
          return unless ein.enabled
          if ein.name_type == :operations_full || ein.name_type == :project_full
            field_name = @elasticsearch_index_name_field
            need_time = true
          else
            field_name = @elasticsearch_index_prefix_field
            need_time = false
          end

          case ein.name_type
          when :operations_full, :operations_prefix
            prefix = ".operations"
          when :project_full, :project_prefix
            name, uuid = nil
            unless record['kubernetes'].nil?
              k8s = record['kubernetes']
              name = k8s['namespace_name']
              uuid = k8s['namespace_id']
              if name.nil?
                log.error("record cannot use elasticsearch index name type #{ein.name_type}: record is missing kubernetes.namespace_name field: #{record}")
              end
              if uuid.nil?
                log.error("record cannot use elasticsearch index name type #{ein.name_type}: record is missing kubernetes.namespace_id field: #{record}")
              end
            else
              log.error("record cannot use elasticsearch index name type #{ein.name_type}: record is missing kubernetes field: #{record}")
            end
            if name.nil? || uuid.nil?
              name = @orphaned_namespace_name
            end
            prefix = name == @orphaned_namespace_name ? @orphaned_namespace_name : "project.#{name}.#{uuid}"
          end

          if ENV['CDM_DEBUG']
            unless tag == ENV['CDM_DEBUG_IGNORE_TAG']
              log.error("prefix #{prefix} need_time #{need_time} time #{record[@dest_time_name]}")
            end
          end

          if need_time
            ts = DateTime.parse(record[@dest_time_name])
            record[field_name] = prefix + "." + ts.strftime("%Y.%m.%d")
          else
            record[field_name] = prefix
          end
          if ENV['CDM_DEBUG']
            unless tag == ENV['CDM_DEBUG_IGNORE_TAG']
              log.error("record[#{field_name}] = #{record[field_name]}")
            end
          end

          break
        end
      end
      unless found
        if ENV['CDM_DEBUG']
          unless tag == ENV['CDM_DEBUG_IGNORE_TAG']
            log.error("no match for tag #{tag}")
          end
        end
      end
    end

    def transform_eventrouter(tag, record)
      return unless @process_kubernetes_events
      if record.key?("event") && record["event"].respond_to?(:key?)
        if record.key?("verb")
          record["event"]["verb"] = record.delete("verb")
        end
        record["kubernetes"] = {} unless record.key?("kubernetes")
        record["kubernetes"]["event"] = record.delete("event")
        if record["kubernetes"]["event"].key?('message')
          ((record['pipeline_metadata'] ||= {})[@pipeline_type.to_s] ||= {})['original_raw_message'] = record['message']
        end
        record['message'] = record["kubernetes"]["event"].delete("message")
        record['time'] = record["kubernetes"]["event"]["metadata"].delete("creationTimestamp") 
      end
    end

    def handle_undefined_fields(tag, time, record)
      if @undefined_to_string || @use_undefined || @undefined_dot_replace_char || (@undefined_max_num_fields > NUM_FIELDS_UNLIMITED)
        # undefined contains all of the fields not in keep_fields
        undefined_keys = record.keys - @keep_fields.keys
        return if undefined_keys.empty?
        if @undefined_max_num_fields > NUM_FIELDS_UNLIMITED && undefined_keys.length > @undefined_max_num_fields
          undefined = {}
          undefined_keys.each{|k|undefined[k] = record.delete(k)}
          record[@undefined_name] = JSON.dump(undefined)
        else
          if @use_undefined
            record[@undefined_name] = {}
            modify_hsh = record[@undefined_name]
          else
            modify_hsh = record
          end
          undefined_keys.each do |k|
            origk = k
            if @use_undefined
              modify_hsh[k] = record.delete(k)
            end
            if @undefined_dot_replace_char && k.index('.')
              newk = k.gsub('.', @undefined_dot_replace_char)
              modify_hsh[newk] = modify_hsh.delete(k)
              k = newk
            end
            if @undefined_to_string && !modify_hsh[k].is_a?(String)
              modify_hsh[k] = JSON.dump(modify_hsh[k])
            end
          end
        end
      end
    end

    def filter(tag, time, record)
      if ENV['CDM_DEBUG']
        unless tag == ENV['CDM_DEBUG_IGNORE_TAG']
          log.error("input #{time} #{tag} #{record}")
        end
      end

      check_for_match_and_format(tag, time, record)
      add_pipeline_metadata(tag, time, record)
      handle_undefined_fields(tag, time, record)
      # remove the field from record if it is not in the list of fields to keep and
      # it is empty
      record.delete_if{|k,v| !@keep_empty_fields_hash.key?(k) && (v.nil? || isempty(delempty(v)) || isempty(v))}
      # probably shouldn't remove everything . . .
      log.warn("Empty record! tag [#{tag}] time [#{time}]") if record.empty?
      # rename the time field
      if (@rename_time || @rename_time_if_missing) && record.key?(@src_time_name)
        val = record.delete(@src_time_name)
        unless @rename_time_if_missing && record.key?(@dest_time_name)
          record[@dest_time_name] = val
        end
      end

      if !@elasticsearch_index_names.empty?
        add_elasticsearch_index_name_field(tag, time, record)
      elsif ENV['CDM_DEBUG']
        unless tag == ENV['CDM_DEBUG_IGNORE_TAG']
          log.error("not adding elasticsearch index name or prefix")
        end
      end
      if ENV['CDM_DEBUG']
        unless tag == ENV['CDM_DEBUG_IGNORE_TAG']
          log.error("output #{time} #{tag} #{record}")
        end
      end
      record
    end
  end
end
