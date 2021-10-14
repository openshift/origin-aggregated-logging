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

require 'fluent/env'
require 'fluent/plugin/base'
require 'fluent/plugin/owned_by_mixin'
require 'fluent/time'

module Fluent
  module Plugin
    class Formatter < Base
      include OwnedByMixin
      include TimeMixin::Formatter

      configured_in :format

      PARSER_TYPES = [:text_per_line, :text, :binary]
      def formatter_type
        :text_per_line
      end

      def format(tag, time, record)
        raise NotImplementedError, "Implement this method in child class"
      end
    end

    class ProcWrappedFormatter < Formatter
      def initialize(proc)
        super()
        @proc = proc
      end

      def format(tag, time, record)
        @proc.call(tag, time, record)
      end
    end

    module Newline
      module Mixin
        include Fluent::Configurable

        DEFAULT_NEWLINE = if Fluent.windows?
                            :crlf
                          else
                            :lf
                          end

        config_param :newline, :enum, list: [:lf, :crlf], default: DEFAULT_NEWLINE

        def configure(conf)
          super
          @newline = case newline
                     when :lf
                       "\n".freeze
                     when :crlf
                       "\r\n".freeze
                     end
        end
      end
    end
  end
end
