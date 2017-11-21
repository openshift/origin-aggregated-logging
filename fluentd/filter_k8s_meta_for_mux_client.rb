#
# This is a replacement for the
# Fluentd Kubernetes Metadata Filter Plugin
# for mux clients that want to defer the k8s processing to mux.
# This does everything which that plugin does, except the k8s
# metadata enrichment.  Right now, that means just the JSON
# parsing of the "log"/"MESSAGE" field.
# NOTE: Tried to use record_transformer with fluentd 0.12.39 - none
# of the changes made to the record inside the ${...} were
# preserved.
# NOTE: Tried to use filter_parser with fluentd 0.12.39 - this came
# close, but it had the following problem: when there are duplicates
# between the original record and the new json parsed hash, the new
# fields will replace the old fields - there is apparently no way
# to change that behavior.
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
module Fluent
  class K8sFilterForMuxClient < Fluent::Filter

    Fluent::Plugin.register_filter('k8s_meta_filter_for_mux_client', self)

    config_param :merge_json_log, :bool, default: true
    config_param :preserve_json_log, :bool, default: true
    config_param :use_journal, :bool, default: false

    def initialize
      super
    end

    def configure(conf)
      super

      if @use_journal
        @merge_json_log_key = 'MESSAGE'
      else
        @merge_json_log_key = 'log'
      end
    end

    def filter_stream(tag, es)
      new_es = MultiEventStream.new

      es.each { |time, record|
        record = merge_json_log(record) if @merge_json_log

        new_es.add(time, record)
      }

      new_es
    end

    def merge_json_log(record)
      if record.has_key?(@merge_json_log_key)
        log = record[@merge_json_log_key].strip
        if log[0].eql?('{') && log[-1].eql?('}')
          begin
            record = JSON.parse(log).merge(record)
            unless @preserve_json_log
              record.delete(@merge_json_log_key)
            end
          rescue JSON::ParserError
          end
        end
      end
      record
    end

  end
end
