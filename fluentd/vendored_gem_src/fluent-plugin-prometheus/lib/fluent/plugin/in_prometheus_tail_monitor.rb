require 'fluent/plugin/input'
require 'fluent/plugin/in_monitor_agent'
require 'fluent/plugin/prometheus'

module Fluent::Plugin
  class PrometheusTailMonitorInput < Fluent::Plugin::Input
    Fluent::Plugin.register_input('prometheus_tail_monitor', self)
    include Fluent::Plugin::PrometheusLabelParser

    helpers :timer

    config_param :interval, :time, default: 1
    attr_reader :registry

    MONITOR_IVARS = [
      :tails,
    ]

    def initialize
      super
      @registry = ::Prometheus::Client.registry
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
        maxfsize: get_gauge(
          :maxfsize,
          'Current max fsize of file on rotation event'),
        countonrotate: get_gauge(
          :countonrotate,
          'No of rotation noticed by fluentd'),
        totalbytesread: get_gauge(
          :totalbytesread,
          'totalbytes read by fluentd IOHandler'),
        totalbytesavailable: get_gauge(
          :totalbytesavailable,
          'totalbytes available at each instance of rotation - to be read by fluentd IOHandler'),
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
          totalbytesread = watcher.instance_variable_get(:@totalbytesread)
          totalbytesavailable = watcher.instance_variable_get(:@totalbytesavailable)
          maxfsize = watcher.instance_variable_get(:@maxfsize)
          countonrotate = watcher.instance_variable_get(:@countonrotate)
          label = labels(info, watcher.path)
          @metrics[:inode].set(label, pe.read_inode)
          @metrics[:position].set(label, pe.read_pos)
          @metrics[:maxfsize].set(label, maxfsize)
          @metrics[:countonrotate].set(label, countonrotate)
          @metrics[:totalbytesread].set(label, totalbytesread)
          @metrics[:totalbytesavailable].set(label, totalbytesavailable)
          #@log.info "IN PROMETHEUS PLUGIN pr.read_inode and pe.read_pos #{pe.read_inode} #{pe.read_pos} maxfsize #{maxfsize} countonrotate #{countonrotate} totalbytesread #{totalbytesread} totalbytesavailable #{totalbytesavailable} "
        end
      end
    end

    def labels(plugin_info, path)
      @base_labels.merge(
        plugin_id: plugin_info["plugin_id"],
        type: plugin_info["type"],
        path: path,
      )
    end

    def get_gauge(name, docstring)
      if @registry.exist?(name)
        @registry.get(name)
      else
        @registry.gauge(name, docstring)
      end
    end
  end
end
