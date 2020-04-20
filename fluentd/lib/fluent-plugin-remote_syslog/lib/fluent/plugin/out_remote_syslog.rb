require "remote_syslog_sender"

module Fluent
  module Plugin
    class RemoteSyslogOutput < Output
      Fluent::Plugin.register_output("remote_syslog", self)

      helpers :formatter, :inject

      config_param :hostname, :string, :default => ""

      config_param :host, :string, :default => nil
      config_param :port, :integer, :default => 514
      config_param :host_with_port, :string, :default => nil

      config_param :facility, :string, :default => "user"
      config_param :severity, :string, :default => "notice"
      config_param :program, :string, :default => "fluentd"
      config_param :rfc, :enum, list: [:rfc3164, :rfc5424], :default => :rfc5424
      config_param :appname, :string, :default => nil
      config_param :procid, :string, :default => nil
      config_param :msgid, :string, :default => nil

      config_param :protocol, :enum, list: [:udp, :tcp], :default => :udp
      config_param :tls, :bool, :default => false
      config_param :ca_file, :string, :default => nil
      config_param :verify_mode, :integer, default: nil
      config_param :packet_size, :size, default: 1024
      config_param :timeout, :time, default: nil
      config_param :timeout_exception, :bool, default: false

      config_param :keep_alive, :bool, :default => false
      config_param :keep_alive_idle, :integer, :default => nil
      config_param :keep_alive_cnt, :integer, :default => nil
      config_param :keep_alive_intvl, :integer, :default => nil

      config_section :buffer do
        config_set_default :flush_mode, :interval
        config_set_default :flush_interval, 5
        config_set_default :flush_thread_interval, 0.5
        config_set_default :flush_thread_burst_interval, 0.5
      end

      config_section :format do
        config_set_default :@type, 'ltsv'
      end

      def initialize
        super
      end

      def configure(conf)
        super
        if @host.nil? && @host_with_port.nil?
          raise ConfigError, "host or host_with_port is required"
        end

        @formatter = formatter_create
        unless @formatter.formatter_type == :text_per_line
          raise ConfigError, "formatter_type must be text_per_line formatter"
        end

        validate_target = "host=#{@host}/host_with_port=#{@host_with_port}/hostname=#{@hostname}/facility=#{@facility}/severity=#{@severity}/program=#{@program}/appname=#{@appname}/procid=#{@procid}/msgid=#{@msgid}"
        placeholder_validate!(:remote_syslog, validate_target)

        @senders = []

      end

      def multi_workers_ready?
        true
      end

      def close
        super
        @senders.each { |s| s.close if s }
        @senders.clear
      end

      def format(tag, time, record)
        r = inject_values_to_record(tag, time, record)
        @formatter.format(tag, time, r)
      end

      def write(chunk)
        return if chunk.empty?

        host = extract_placeholders(@host, chunk.metadata)
        port = @port

        if @host_with_port
          host, port = extract_placeholders(@host_with_port, chunk.metadata).split(":")
        end

        host_with_port = "#{host}:#{port}"

        Thread.current[host_with_port] ||= create_sender(host, port)
        sender = Thread.current[host_with_port]

        facility = extract_placeholders(@facility, chunk.metadata)
        facility = sanitize_facility(facility)
        severity = extract_placeholders(@severity, chunk.metadata)
        severity = sanitize_severity(severity)
        program = extract_placeholders(@program, chunk.metadata)
        hostname = extract_placeholders(@hostname, chunk.metadata)

        packet_options = {facility: facility, severity: severity, program: program}
        packet_options[:faciity] = 'user' if packet_options[:facility].nil? ||  packet_options[:facility].strip.empty?
        packet_options[:severity] = 'notice' if packet_options[:severity].nil? ||  packet_options[:severity].strip.empty?

        packet_options[:hostname] = hostname unless hostname.empty?
        packet_options[:rfc] = @rfc
        if @rfc == :rfc3164
          packet_options[:program] = program
        end
        if @rfc == :rfc5424
          appname = extract_placeholders(@appname, chunk.metadata) unless @appname == nil || @appname.length == 0
          packet_options[:appname] = appname unless appname == nil || appname.length == 0
          procid = extract_placeholders(@procid, chunk.metadata) unless @procid == nil || @procid.length == 0 
          packet_options[:procid] = procid unless procid == nil || procid.length == 0
          msgid = extract_placeholders(@msgid, chunk.metadata) unless @msgid == nil || @msgid.length == 0
          packet_options[:msgid] = msgid unless msgid == nil || msgid.length == 0
        end

        begin
          chunk.open do |io|
            io.each_line do |msg|
              sender.transmit(msg.chomp!, packet_options)
            end
          end
        rescue
          if Thread.current[host_with_port]
            Thread.current[host_with_port].close
            @senders.delete(Thread.current[host_with_port])
            Thread.current[host_with_port] = nil
          end
          raise
        end
      end

      private

      # To create a mapping between https://en.wikipedia.org/wiki/Syslog#Facility_Levels
      # and string values supported by syslog_protocol plugin
      def sanitize_facility(facility)
        new_facility = facility.downcase
        case facility.downcase
        when "security"
          new_facility = "audit"
        when "console"
          new_facility = "alert"
        when "solaris-cron"
          new_facility = "at"
        end
        new_facility
      end

      # To create a mapping between https://tools.ietf.org/html/rfc5424#section-6.2.1
      # and string values supported by syslog_protocol plugin
      def sanitize_severity(severity)
        new_severity = severity.downcase
        case severity.downcase
        when "emergency"
          new_severity = "emerg"
        when "alert"
          new_severity = "alert"
        when "critical"
          new_severity = "crit"
        when "error"
          new_severity = "err"
        when "warning"
          new_severity = "warn"
        when "notice"
          new_severity = "notice"
        when "informational"
          new_severity = "info"
        when "debug"
          new_severity = "debug"
        end
        new_severity
      end

      def create_sender(host, port)
        if @protocol == :tcp
          options = {
            tls: @tls,
            whinyerrors: true,
            packet_size: @packet_size,
            timeout: @timeout,
            timeout_exception: @timeout_exception,
            keep_alive: @keep_alive,
            keep_alive_idle: @keep_alive_idle,
            keep_alive_cnt: @keep_alive_cnt,
            keep_alive_intvl: @keep_alive_intvl,
            program: @program,
          }
          options[:ca_file] = @ca_file if @ca_file
          options[:verify_mode] = @verify_mode if @verify_mode
          sender = RemoteSyslogSender::TcpSender.new(
            host,
            port,
            options
          )
        else
          sender = RemoteSyslogSender::UdpSender.new(
            host,
            port,
            whinyerrors: true,
            program: @program,
          )
        end
        @senders << sender
        sender
      end
    end
  end
end
