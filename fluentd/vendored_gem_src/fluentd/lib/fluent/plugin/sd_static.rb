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

require 'fluent/plugin/service_discovery'

module Fluent
  module Plugin
    class StaticServiceDiscovery < ServiceDiscovery
      Plugin.register_sd('static', self)

      LISTEN_PORT = 24224

      config_section :service, param_name: :service_configs do
        desc 'The IP address or host name of the server.'
        config_param :host, :string
        desc 'The name of the server. Used for logging and certificate verification in TLS transport (when host is address).'
        config_param :name, :string, default: nil
        desc 'The port number of the host.'
        config_param :port, :integer, default: LISTEN_PORT
        desc 'The shared key per server.'
        config_param :shared_key, :string, default: nil, secret: true
        desc 'The username for authentication.'
        config_param :username, :string, default: ''
        desc 'The password for authentication.'
        config_param :password, :string, default: '', secret: true
        desc 'Marks a node as the standby node for an Active-Standby model between Fluentd nodes.'
        config_param :standby, :bool, default: false
        desc 'The load balancing weight.'
        config_param :weight, :integer, default: 60
      end

      def configure(conf)
        super

        @services = @service_configs.map do |s|
          ServiceDiscovery::Service.new(:static, s.host, s.port, s.name, s.weight, s.standby, s.username, s.password, s.shared_key)
        end
      end

      def start(queue = nil)
        super()
      end
    end
  end
end
