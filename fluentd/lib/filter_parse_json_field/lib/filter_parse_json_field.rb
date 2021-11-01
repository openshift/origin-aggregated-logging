#
# Parse JSON valued fields into JSON objects and put those
# parsed fields into the record.  Look for the fields specified
# in the json_fields config_param.  If the record has the key,
# see if it is a JSON valued string, parse it, and add it to
# the record, and return the record, ignoring any remaining
# fields in json_fields.  By default, look for the 'MESSAGE'
# field, then the 'log' field.
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
module Fluent::Plugin
  class ParseJSONFieldFilter < Fluent::Plugin::Filter

    Fluent::Plugin.register_filter('parse_json_field', self)

    config_param :merge_json_log, :bool, default: true
    config_param :preserve_json_log, :bool, default: true
    config_param :replace_json_log, :bool, default: false
    config_param :json_fields, :array, default: ['MESSAGE', 'log']

    def initialize
      super
    end

    def configure(conf)
      super
    end

    def filter_stream(tag, es)
      return es unless @merge_json_log || @replace_json_log
      new_es = Fluent::MultiEventStream.new
      if @merge_json_log
        es.each { |time, record|
          record = do_merge_json_log(record)
          new_es.add(time, record)
        }
      elsif @replace_json_log
        es.each { |time, record|
          record = do_replace_json_log(record)
          new_es.add(time, record)
        }
      end
      new_es

    end

    def do_merge_json_log(record)
      json_fields.each do |merge_json_log_key|
        if record.has_key?(merge_json_log_key)
          value = record[merge_json_log_key] || ''
          value = value.strip if value.respond_to?(:strip)
          if value.respond_to?(:start_with?) && value.respond_to?(:end_with?) &&
            (value.start_with?('{') && value.end_with?('}'))
            begin
              record = JSON.parse(value).merge(record)
              unless @preserve_json_log
                record.delete(merge_json_log_key)
              end
            rescue JSON::ParserError
              log.debug "parse_json_field could not parse field [#{merge_json_log_key}] as JSON: value [#{value}]"
            end
          end
          break
        end
      end
      record
    end

    def do_replace_json_log(record)
      json_fields.each do |merge_json_log_key|
        if record.has_key?(merge_json_log_key)
          value = record[merge_json_log_key] || ''
          value = value.strip if value.respond_to?(:strip)
          if value.respond_to?(:start_with?) && value.respond_to?(:end_with?) &&
             (value.start_with?('{') && value.end_with?('}'))
            begin
              parsed_value = JSON.parse(value)
              record[merge_json_log_key] = parsed_value
            rescue JSON::ParserError
              log.debug "parse_json_field could not parse field [#{merge_json_log_key}] as JSON: value [#{value}]"
            end
            end
          break
        end
      end
      record
    end
  end
end
