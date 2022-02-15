require 'fluent/plugin/input'
require 'fluent/plugin/in_monitor_agent'
require 'fluent/plugin/prometheus'

module Fluent::Plugin
  # Collect log_collected_bytes_total metric from in_tail plugin.
  class CollectedTailMonitorInput < Fluent::Plugin::Input
    Fluent::Plugin.register_input('collected_tail_monitor', self)
    include Fluent::Plugin::PrometheusLabelParser

    helpers :timer

    #ideally interval must be rotatewait > 0 ? rotatewait/2 : 1.0
    #and if interval >= rotate_wait we should log a warning.
    #For rotatewait = 5 sec, interval can be set to 2 sec


    config_param :interval, :time, default: 2
    attr_reader :registry

    MONITOR_IVARS = [
      :tails,
    ]

    REGEX_VAR_LOG_PODS = Regexp.new('/var/log/pods/(?<namespace>[a-z0-9-]+)_(?<pod_name>[a-z0-9-]+)_(?<pod_uuid>[a-z0-9-]+)/(?<container_name>[a-z0-9-]+)/.*\.log$')
    REGEX_VAR_LOG_CONTAINERS = Regexp.new('/var/log/containers/(?<pod_name>[a-z0-9-]+)_(?<namespace>[a-z0-9-]+)_(?<container_name>[a-z0-9-]+)-(?<docker_id>[a-z0-9]{64})\.log$')
    REGEX_LOG_PATH=/(#{REGEX_VAR_LOG_PODS})|(#{REGEX_VAR_LOG_CONTAINERS})/

    def initialize
      super
      @registry = ::Prometheus::Client.registry
      # As per k8 regex for container logfile symlink ref :
      # https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter/blob/master/lib/fluent/plugin/filter_kubernetes_metadata.rb#L56
    end

    def multi_workers_ready?
      true
    end

    def configure(conf)
      super
      hostname = Socket.gethostname
      expander_builder = Fluent::Plugin::Prometheus.placeholder_expander(log)
      expander = expander_builder.build({ 'hostname' => hostname, 'worker_id' => fluentd_worker_id })
      @base_labels = parse_labels_elements(conf)
      @base_labels.each do |key, value|
        unless value.is_a?(String)
          raise Fluent::ConfigError, "record accessor syntax is not available in collected_tail_monitor"
        end
        @base_labels[key] = expander.expand(value)
      end

      if defined?(Fluent::Plugin) && defined?(Fluent::Plugin::MonitorAgentInput)
        # from v0.14.6
        @monitor_agent = Fluent::Plugin::MonitorAgentInput.new
      else
        @monitor_agent = Fluent::MonitorAgentInput.new
      end
    end

    def start
      super

      @metrics = {
        total_bytes_collected: get_counter(
          :log_collected_bytes_total,
          'Total bytes collected from file.'),
      }
      timer_execute(:in_collected_tail_monitor, @interval, &method(:update_monitor_info))
    end


    def update_monitor_info
      opts = {
        ivars: MONITOR_IVARS,
      }

     agent_info = @monitor_agent.plugins_info_all(opts).select do |info|
        info['type'] == 'tail'.freeze
     end
      agent_info.each do |info|
        tails = info['instance_variables'][:tails]
        next if tails.nil?

        tails.clone.each do |_, watcher|
          # Access to internal variable of internal class...
          # Very fragile implementation, borrowed from the standard prometheus_tail_monitor
          pe = watcher.instance_variable_get(:@pe)
          label = labels(info, watcher.path)

          # Compare pos/inode with the last time we saw this tail
          old_pos = pe.instance_variable_get(:@_old_pos) || 0.0
          pe.instance_variable_set(:@_old_pos, pe.read_pos)
          old_inode = pe.instance_variable_get(:@_old_inode)
          pe.instance_variable_set(:@_old_inode, pe.read_inode)
          if pe.read_inode == old_inode && pe.read_pos >= old_pos
            # Same file, has not been truncated since last we looked. Add the delta.
            @log.trace "delta bytes #{pe.read_pos}  #{old_pos}"
            @metrics[:total_bytes_collected].increment(label, pe.read_pos - old_pos)
          else
            # Changed file or truncated the existing file. Add the initial content.
            @log.trace "delta bytes #{pe.read_pos}"
            @metrics[:total_bytes_collected].increment(label, pe.read_pos)
          end
        end
      end
    end

    def labels(plugin_info, path)
      labels = { plugin_id: plugin_info['plugin_id'],
                 type: plugin_info['type'],
                 path: path }
      # Extract labels from path, handle /var/log/pods and /var/log/containers formats.
      if (m = path.match(REGEX_LOG_PATH))
        labels[:namespace] = m['namespace']
        labels[:podname] = m['pod_name']
        labels[:containername] = m['container_name']
      end
      labels.merge!(@base_labels) # ! to avoid allocating another map
    end

    def get_counter(name, docstring)
      if @registry.exist?(name)
        @registry.get(name)
      else
        @registry.counter(name, docstring)
      end
    end
  end
end
