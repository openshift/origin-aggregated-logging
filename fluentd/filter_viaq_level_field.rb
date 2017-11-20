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
# This filter will process the `level` field in the ViaQ top level schema:
# https://github.com/ViaQ/fluent-plugin-viaq_data_model/blob/master/lib/fluent/plugin/filter_viaq_data_model.rb#L228
module Fluent
    class K8sFilterForMuxClient < Fluent::Filter
  
      Fluent::Plugin.register_filter('viaq_level_field', self)
    
      def initialize
        super
      end
  
      def configure(conf)
        super
      end
  
      def filter(tag, time, record)
        if newlevel = normalize_level(record['level'], nil, record['stream'], record['PRIORITY'])
          record['level'] = newlevel
        end
        record
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
        retlevel
      end  
    end
  end
  