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

module Fluent
  module PluginHelper
    module ServiceDiscovery
      class RoundRobinBalancer
        def initialize
          @services = []
          @mutex = Mutex.new
        end

        def rebalance(services)
          @mutex.synchronize do
            @services = services
          end
        end

        def select_service
          s = @mutex.synchronize do
            s = @services.shift
            @services.push(s)
            s
          end
          yield(s)
        end
      end
    end
  end
end
