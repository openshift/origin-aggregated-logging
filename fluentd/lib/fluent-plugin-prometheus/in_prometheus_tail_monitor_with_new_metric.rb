require 'fluent/plugin/input'
require 'fluent/plugin/in_monitor_agent'
require 'fluent/plugin/prometheus'

module Fluent::Plugin
  class PrometheusTailMonitorInput < Fluent::Plugin::Input
    Fluent::Plugin.register_input('prometheus_tail_monitor', self)
    include Fluent::Plugin::PrometheusLabelParser

    helpers :timer

    config_param :interval, :time, default: 5
    attr_reader :registry

    MONITOR_IVARS = [
      :tails,
    ]

    def initialize
      super
      @registry = ::Prometheus::Client.registry
      @prev_total_bytes_collected={}
      # As per k8 regex for container logfile symlink ref :  https://github.com/fabric8io/fluent-plugin-kubernetes_metadata_filter/blob/master/lib/fluent/plugin/filter_kubernetes_metadata.rb#L56
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
          raise Fluent::ConfigError, "record accessor syntax is not available in prometheus_tail_monitor"
        end
        @base_labels[key] = expander.expand(value)
      end

      @monitor_agent = Fluent::Plugin::MonitorAgentInput.new
    end

    def start
      super

      @metrics = {
        position: get_gauge(
          :fluentd_tail_file_position,
          'Current position of file.'),
        inode: get_gauge(
          :fluentd_tail_file_inode,
          'Current inode of file.'),
        total_bytes_collected: get_counter(
          :log_collected_bytes_total,
          'logs total bytes collected by fluentd.'),
      }
      timer_execute(:in_prometheus_tail_monitor, @interval, &method(:update_monitor_info))
    end

    def update_monitor_info
      opts = {
        ivars: MONITOR_IVARS,
      }

      agent_info = @monitor_agent.plugins_info_all(opts).select {|info|
        info['type'] == 'tail'.freeze
      }

      agent_info.each do |info|
        tails = info['instance_variables'][:tails]
        next if tails.nil?

        tails.clone.each do |_, watcher|
          # Access to internal variable of internal class...
          # Very fragile implementation
          pe = watcher.instance_variable_get(:@pe)
          total_bytes_collected=watcher.instance_variable_get(:@total_bytes_collected)
          label = labels(info, watcher.path)
          @log.info "label #{label}"
          @metrics[:inode].set(label, pe.read_inode)
          @metrics[:position].set(label, pe.read_pos)
          if (@prev_total_bytes_collected[label] == nil) 
            @prev_total_bytes_collected[label]=0
          end
          @metrics[:total_bytes_collected].increment(label, total_bytes_collected - @prev_total_bytes_collected[label])
          @prev_total_bytes_collected[label]=total_bytes_collected
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
      
        @log.info "path #{path}, namespace #{namespace}, podname #{podname[0]},containername #{containername}"

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
        )
      end

    end

    def get_gauge(name, docstring)
      if @registry.exist?(name)
        @registry.get(name)
      else
        @registry.gauge(name, docstring)
      end
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
