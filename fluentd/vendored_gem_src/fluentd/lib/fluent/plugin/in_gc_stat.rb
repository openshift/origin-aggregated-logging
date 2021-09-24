#
# Fluentd
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

require 'fluent/plugin/input'

module Fluent::Plugin
  class GCStatInput < Fluent::Plugin::Input
    Fluent::Plugin.register_input('gc_stat', self)

    helpers :timer

    def initialize
      super
      @key_map = nil
    end

    config_param :emit_interval, :time, default: 60
    config_param :use_symbol_keys, :bool, default: true
    config_param :tag, :string

    def configure(conf)
      super

      unless @use_symbol_keys
        @key_map = {}
        GC.stat.each_key { |key|
          @key_map[key] = key.to_s
        }
      end
    end

    def multi_workers_ready?
      true
    end

    def start
      super

      timer_execute(:in_gc_stat, @emit_interval, &method(:on_timer))
    end

    def shutdown
      super
    end

    def on_timer
      now = Fluent::EventTime.now
      record = GC.stat
      unless @use_symbol_keys
        new_record = {}
        record.each_pair { |k, v|
          new_record[@key_map[k]] = v
        }
        record = new_record
      end
      router.emit(@tag, now, record)
    end
  end
end
