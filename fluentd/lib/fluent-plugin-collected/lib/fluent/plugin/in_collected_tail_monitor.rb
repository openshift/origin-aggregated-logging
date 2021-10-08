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

    def initialize
      super
      @registry = ::Prometheus::Client.registry
      # As per k8 regex for container logfile symlink ref :  
      # https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter/blob/master/lib/fluent/plugin/filter_kubernetes_metadata.rb#L56

      @tag_to_kubernetes_filename_regexp_compiled = Regexp.new('var.log.containers.(?<pod_name>[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*)_(?<namespace>[^_]+)_(?<container_name>.+)-(?<docker_id>[a-z0-9]{64})\.log$')

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
            @metrics[:total_bytes_collected].increment(by: pe.read_pos - old_pos, labels: label)
          else
            # Changed file or truncated the existing file. Add the initial content.
            @log.trace "delta bytes #{pe.read_pos}"
            @metrics[:total_bytes_collected].increment(by: pe.read_pos, labels: label)
          end
        end
      end
    end

    def labels(plugin_info, path)
      #taking out dirname and .log from the full pathname e.g. /var/log/containers/xxx.log --> xxx
      #k8 regexp for parsing container generated logfile pathname into namespace, podname, containername
      path_match_data = path.match(@tag_to_kubernetes_filename_regexp_compiled)
      if path_match_data
        podname = path_match_data['pod_name'],
        namespace = path_match_data['namespace'],
        containername = path_match_data['container_name'],
        dockerid = path_match_data['docker_id']
        
        @log.trace "path #{path}, namespace #{namespace}, podname #{podname[0]},containername #{containername}"

        @base_labels.merge(
        plugin_id: plugin_info["plugin_id"],
        type: plugin_info["type"],
        path: path,
        namespace: namespace,
        podname: podname[0],
        containername: containername,
      )
      else
        @base_labels.merge(
        plugin_id: plugin_info["plugin_id"],
        type: plugin_info["type"],
        path: path,
        namespace: "notfound",
        podname: "notfound",
        containername: "notfound",
        )
      end
    end

    def get_counter(name, docstring)
      if @registry.exist?(name)
        @registry.get(name)
      else
        @registry.counter(
          name,
          docstring: docstring,
          labels: [:hostname, :plugin_id, :type, :path, :namespace, :podname, :containername]
        )
      end
    end

  end
end
