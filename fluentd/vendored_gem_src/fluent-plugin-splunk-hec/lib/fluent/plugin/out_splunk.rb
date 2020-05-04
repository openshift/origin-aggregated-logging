# frozen_string_literal: true

require 'fluent/output'
require 'fluent/plugin/output'
require 'fluent/plugin/formatter'
require 'prometheus/client'
require 'benchmark'

module Fluent::Plugin
  class SplunkOutput < Fluent::BufferedOutput
    helpers :formatter

    autoload :VERSION, 'fluent/plugin/out_splunk/version'
    autoload :MatchFormatter, 'fluent/plugin/out_splunk/match_formatter'

    KEY_FIELDS = %w[index host source sourcetype metric_name metric_value].freeze
    TAG_PLACEHOLDER = '${tag}'

    desc 'The host field for events, by default it uses the hostname of the machine that runnning fluentd. This is exclusive with `host_key`.'
    config_param :host, :string, default: nil

    desc 'Field name to contain host. This is exclusive with `host`.'
    config_param :host_key, :string, default: nil

    desc 'The source field for events, when not set, will be decided by HEC. This is exclusive with `source_key`.'
    config_param :source, :string, default: nil

    desc 'Field name to contain source. This is exclusive with `source`.'
    config_param :source_key, :string, default: nil

    desc 'The sourcetype field for events, when not set, will be decided by HEC. This is exclusive with `sourcetype_key`.'
    config_param :sourcetype, :string, default: nil

    desc 'Field name to contain sourcetype. This is exclusive with `sourcetype`.'
    config_param :sourcetype_key, :string, default: nil

    desc 'Field name to contain Splunk event time. By default will use fluentd\'d time'
    config_param :time_key, :string, default: nil

    desc 'The Splunk index to index events. When not set, will be decided by HEC. This is exclusive with `index_key`'
    config_param :index, :string, default: nil

    desc 'Field name to contain Splunk index name. This is exclusive with `index`.'
    config_param :index_key, :string, default: nil

    desc 'When set to true, all fields defined in `index_key`, `host_key`, `source_key`, `sourcetype_key`, `metric_name_key`, `metric_value_key` will not be removed from the original event.'
    config_param :keep_keys, :bool, default: false

    desc 'Define index-time fields for event data type, or metric dimensions for metric data type. Null value fields will be removed.'
    config_section :fields, init: false, multi: false, required: false do
      # this is blank on purpose
    end

    config_section :format do
      config_set_default :usage, '**'
      config_set_default :@type, 'json'
      config_set_default :add_newline, false
    end

    desc <<~DESC
      Whether to allow non-UTF-8 characters in user logs. If set to true, any
      non-UTF-8 character would be replaced by the string specified by
      `non_utf8_replacement_string`. If set to false, any non-UTF-8 character
      would trigger the plugin to error out.
    DESC
    config_param :coerce_to_utf8, :bool, default: true

    desc <<~DESC
      If `coerce_to_utf8` is set to true, any non-UTF-8 character would be
      replaced by the string specified here.
    DESC
    config_param :non_utf8_replacement_string, :string, default: ' '

    def initialize
      super
      @registry = ::Prometheus::Client.registry
    end

    def configure(conf)
      super
      check_conflict
      @api = construct_api
      prepare_key_fields
      configure_fields(conf)
      configure_metrics(conf)

      # @formatter_configs is from formatter helper
      @formatters = @formatter_configs.map do |section|
        MatchFormatter.new section.usage, formatter_create(usage: section.usage)
      end
    end

    def write(chunk)
      log.trace { "#{self.class}: Received new chunk, size=#{chunk.read.bytesize}" }

      t = Benchmark.realtime do
        write_to_splunk(chunk)
      end

      @metrics[:record_counter].increment(metric_labels, chunk.size_of_events)
      @metrics[:bytes_counter].increment(metric_labels, chunk.bytesize)
      @metrics[:write_records_histogram].observe(metric_labels, chunk.size_of_events)
      @metrics[:write_bytes_histogram].observe(metric_labels, chunk.bytesize)
      @metrics[:write_latency_histogram].observe(metric_labels, t)
    end

    def write_to_splunk(_chunk)
      raise NotImplementedError("Child class should implement 'write_to_splunk'")
    end

    def construct_api
      raise NotImplementedError("Child class should implement 'construct_api'")
    end

    protected

    def prepare_event_payload(tag, time, record)
      {
        host: @host ? @host.call(tag, record) : @default_host,
        # From the API reference
        # http://docs.splunk.com/Documentation/Splunk/latest/RESTREF/RESTinput#services.2Fcollector
        # `time` should be a string or unsigned integer.
        # That's why we use `to_s` here.
        time: time.to_f.to_s
      }.tap do |payload|
        payload[:index] = @index.call(tag, record) if @index
        payload[:source] = @source.call(tag, record) if @source
        payload[:sourcetype] = @sourcetype.call(tag, record) if @sourcetype

        # delete nil fields otherwise will get format error from HEC
        %i[host index source sourcetype].each { |f| payload.delete f if payload[f].nil? }

        if @extra_fields
          payload[:fields] = @extra_fields.map { |name, field| [name, record[field]] }.to_h
          payload[:fields].compact!
          # if a field is already in indexed fields, then remove it from the original event
          @extra_fields.values.each { |field| record.delete field }
        end
        if formatter = @formatters.find { |f| f.match? tag }
          record = formatter.format(tag, time, record)
        end
        payload[:event] = convert_to_utf8 record
      end
    end

    def format_event(tag, time, record)
      MultiJson.dump(prepare_event_payload(tag, time, record))
    end

    def process_response(response, _request_body)
      log.trace { "[Response] POST #{@api}: #{response.inspect}" }

      @metrics[:status_counter].increment(metric_labels(status: response.code.to_s))

      # raise Exception to utilize Fluentd output plugin retry mechanism
      raise "Server error (#{response.code}) for POST #{@api}, response: #{response.body}" if response.code.to_s.start_with?('5')

      # For both success response (2xx) and client errors (4xx), we will consume the chunk.
      # Because there probably a bug in the code if we get 4xx errors, retry won't do any good.
      unless response.code.to_s.start_with?('2')
        log.error "#{self.class}: Failed POST to #{@api}, response: #{response.body}"
        log.error { "#{self.class}: Failed request body: #{post.body}" }
      end
    end

    private

    def check_conflict
      KEY_FIELDS.each do |f|
        kf = "#{f}_key"
        raise Fluent::ConfigError, "Can not set #{f} and #{kf} at the same time." \
          if %W[@#{f} @#{kf}].all? &method(:instance_variable_get)
      end
    end

    def prepare_key_fields
      KEY_FIELDS.each do |f|
        v = instance_variable_get "@#{f}_key"
        if v
          attrs = v.split('.').freeze
          if @keep_keys
            instance_variable_set "@#{f}", ->(_, record) { attrs.inject(record) { |o, k| o[k] } }
          else
            instance_variable_set "@#{f}", lambda { |_, record|
              attrs[0...-1].inject(record) { |o, k| o[k] }.delete(attrs[-1])
            }
          end
        else
          v = instance_variable_get "@#{f}"
          next unless v

          if v == TAG_PLACEHOLDER
            instance_variable_set "@#{f}", ->(tag, _) { tag }
          else
            instance_variable_set "@#{f}", ->(_, _) { v }
          end
        end
      end
    end

    # <fields> directive, which defines:
    # * when data_type is event, index-time fields
    # * when data_type is metric, metric dimensions
    def configure_fields(conf)
      # This loop looks dump, but it is used to suppress the unused parameter configuration warning
      # Learned from `filter_record_transformer`.
      conf.elements.select { |element| element.name == 'fields' }.each do |element|
        element.each_pair { |k, _v| element.key?(k) }
      end

      return unless @fields

      @extra_fields = @fields.corresponding_config_element.map do |k, v|
        [k, v.empty? ? k : v]
      end.to_h
      end

    def pick_custom_format_method
      if @data_type == :event
        define_singleton_method :format, method(:format_event)
      else
        define_singleton_method :format, method(:format_metric)
      end
    end

    def configure_metrics(conf)
      @metric_labels = {
        type: conf['@type'],
        plugin_id: plugin_id
      }

      @metrics = {
        record_counter: register_metric(::Prometheus::Client::Counter.new(
                                          :splunk_output_write_records_count,
                                          'The number of log records being sent'
                                        )),
        bytes_counter: register_metric(::Prometheus::Client::Counter.new(
                                         :splunk_output_write_bytes_count,
                                         'The number of log bytes being sent'
                                       )),
        status_counter: register_metric(::Prometheus::Client::Counter.new(
                                          :splunk_output_write_status_count,
                                          'The count of sends by response_code'
                                        )),
        write_bytes_histogram: register_metric(::Prometheus::Client::Histogram.new(
                                                 :splunk_output_write_payload_bytes,
                                                 'The size of the write payload in bytes', {}, [1024, 23_937, 47_875, 95_750, 191_500, 383_000, 766_000, 1_149_000]
                                               )),
        write_records_histogram: register_metric(::Prometheus::Client::Histogram.new(
                                                   :splunk_output_write_payload_records,
                                                   'The number of records written per write', {}, [1, 10, 25, 100, 200, 300, 500, 750, 1000, 1500]
                                                 )),
        write_latency_histogram: register_metric(::Prometheus::Client::Histogram.new(
                                                   :splunk_output_write_latency_seconds,
                                                   'The latency of writes'
                                                 ))
      }
    end

    # Tag metrics with the type string that was used to register the plugin
    def metric_labels(other_labels = {})
      @metric_labels.merge other_labels
    end

    # Encode as UTF-8. If 'coerce_to_utf8' is set to true in the config, any
    # non-UTF-8 character would be replaced by the string specified by
    # 'non_utf8_replacement_string'. If 'coerce_to_utf8' is set to false, any
    # non-UTF-8 character would trigger the plugin to error out.
    # Thanks to
    # https://github.com/GoogleCloudPlatform/fluent-plugin-google-cloud/blob/dbc28575/lib/fluent/plugin/out_google_cloud.rb#L1284
    def convert_to_utf8(input)
      if input.is_a?(Hash)
        record = {}
        input.each do |key, value|
          record[convert_to_utf8(key)] = convert_to_utf8(value)
        end

        return record
      end
      return input.map { |value| convert_to_utf8(value) } if input.is_a?(Array)
      return input unless input.respond_to?(:encode)

      if @coerce_to_utf8
        input.encode(
          'utf-8',
          invalid: :replace,
          undef: :replace,
          replace: @non_utf8_replacement_string
        )
      else
        begin
          input.encode('utf-8')
        rescue EncodingError
          log.error do
            'Encountered encoding issues potentially due to non ' \
              		     'UTF-8 characters. To allow non-UTF-8 characters and ' \
              		     'replace them with spaces, please set "coerce_to_utf8" ' \
              		     'to true.'
          end
          raise
        end
      end
    end

    def register_metric(metric)
      if !@registry.exist?(metric.name)
        @registry.register(metric)
      else
        @registry.get(metric.name)
      end
    end
  end
end
