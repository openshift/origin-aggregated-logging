# frozen_string_literal: true
$LOAD_PATH.unshift(File.expand_path('..', __dir__))
require 'fluent/env'
require 'fluent/output'
require 'fluent/plugin/output'
require 'fluent/plugin/formatter'
require 'fluent/plugin/out_splunk'

require 'openssl'
require 'multi_json'
require 'net/http/persistent'

module Fluent::Plugin
  class SplunkHecOutput < SplunkOutput
    Fluent::Plugin.register_output('splunk_hec', self)

    helpers :formatter

    autoload :VERSION, "fluent/plugin/out_splunk_hec/version"
    autoload :MatchFormatter, "fluent/plugin/out_splunk_hec/match_formatter"

    KEY_FIELDS = %w[index time host source sourcetype metric_name metric_value].freeze
    TAG_PLACEHOLDER = '${tag}'.freeze

    MISSING_FIELD = Hash.new do |_h, k|
      $log.warn "expected field #{k} but it's missing" if defined?($log)
      MISSING_FIELD
    end.freeze

    desc 'Protocol to use to call HEC API.'
    config_param :protocol, :enum, list: %i[http https], default: :https

    desc 'The hostname/IP to HEC, or HEC load balancer.'
    config_param :hec_host, :string

    desc 'The port number to HEC, or HEC load balancer.'
    config_param :hec_port, :integer, default: 8088

    desc 'The HEC token.'
    config_param :hec_token, :string

    desc 'If a connection has not been used for this number of seconds it will automatically be reset upon the next use to avoid attempting to send to a closed connection. nil means no timeout.'
    config_param :idle_timeout, :integer, default: 5

    desc 'The amount of time allowed between reading two chunks from the socket.'
    config_param :read_timeout, :integer, default: nil

    desc 'The amount of time to wait for a connection to be opened.'
    config_param :open_timeout, :integer, default: nil

    desc 'The path to a file containing a PEM-format CA certificate for this client.'
    config_param :client_cert, :string, default: nil

    desc 'The private key for this client.'
    config_param :client_key, :string, default: nil

    desc 'The path to a file containing a PEM-format CA certificate.'
    config_param :ca_file, :string, default: nil

    desc 'The path to a directory containing CA certificates in PEM format.'
    config_param :ca_path, :string, default: nil

    desc 'List of SSL ciphers allowed.'
    config_param :ssl_ciphers, :array, default: nil

    desc 'When set to true, TLS version 1.1 and above is required.'
    config_param :require_ssl_min_version, :bool, default: true

    desc 'Indicates if insecure SSL connection is allowed.'
    config_param :insecure_ssl, :bool, default: false

    desc 'Type of data sending to Splunk, `event` or `metric`. `metric` type is supported since Splunk 7.0. To use `metric` type, make sure the index is a metric index.'
    config_param :data_type, :enum, list: %i[event metric], default: :event

    desc 'The Splunk index to index events. When not set, will be decided by HEC. This is exclusive with `index_key`'
    config_param :index, :string, default: nil

    desc 'Field name to contain Splunk index name. This is exclusive with `index`.'
    config_param :index_key, :string, default: nil

    desc 'When `data_type` is set to "metric", by default it will treat every key-value pair in the income event as a metric name-metric value pair. Set `metrics_from_event` to `false` to disable this behavior and use `metric_name_key` and `metric_value_key` to define metrics.'
    config_param :metrics_from_event, :bool, default: true

    desc 'Field name to contain metric name. This is exclusive with `metrics_from_event`, when this is set, `metrics_from_event` will be set to `false`.'
    config_param :metric_name_key, :string, default: nil

    desc 'Field name to contain metric value, this is required when `metric_name_key` is set.'
    config_param :metric_value_key, :string, default: nil

    desc 'When set to true, all fields defined in `index_key`, `host_key`, `source_key`, `sourcetype_key`, `metric_name_key`, `metric_value_key` will not be removed from the original event.'
    config_param :keep_keys, :bool, default: false

    desc 'App name'
    config_param :app_name, :string, default: "hec_plugin_gem"

    desc 'App version'
    config_param :app_version, :string, default: "#{VERSION}"

    desc 'Define index-time fields for event data type, or metric dimensions for metric data type. Null value fields will be removed.'
    config_section :fields, init: false, multi: false, required: false do
      # this is blank on purpose
    end

    desc 'Indicates if 4xx errors should consume chunk'
    config_param :consume_chunk_on_4xx_errors, :bool, :default => true

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
    config_param :coerce_to_utf8, :bool, :default => true

    desc <<~DESC
    If `coerce_to_utf8` is set to true, any not-UTF-8 char's would be
    replaced by the string specified here.
    DESC
    config_param :non_utf8_replacement_string, :string, :default => ' '

    def initialize
      super
      @default_host = Socket.gethostname
      @extra_fields = nil
    end

    def configure(conf)
      super

      check_metric_configs
      pick_custom_format_method
    end

    def start
      super
      @conn = Net::HTTP::Persistent.new.tap do |c|
        c.verify_mode = @insecure_ssl ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
        c.cert = OpenSSL::X509::Certificate.new File.read(@client_cert) if @client_cert
        c.key = OpenSSL::PKey::RSA.new File.read(@client_key) if @client_key
        c.ca_file = @ca_file
        c.ca_path = @ca_path
        c.ciphers = @ssl_ciphers
        c.proxy   = :ENV
        c.min_version = OpenSSL::SSL::TLS1_1_VERSION if @require_ssl_min_version

        c.override_headers['Content-Type'] = 'application/json'
        c.override_headers['User-Agent'] = "fluent-plugin-splunk_hec_out/#{VERSION}"
        c.override_headers['Authorization'] = "Splunk #{@hec_token}"
        c.override_headers['__splunk_app_name'] = "#{@app_name}"
        c.override_headers['__splunk_app_version'] = "#{@app_version}"

      end
    end

    def shutdown
      super
      @conn.shutdown
    end

    def format(tag, time, record)
      # this method will be replaced in `configure`
    end

    def multi_workers_ready?
      true
    end

    protected

    private

    def check_metric_configs
      return unless @data_type == :metric

      @metrics_from_event = false if @metric_name_key

      return if @metrics_from_event

      raise Fluent::ConfigError, '`metric_name_key` is required when `metrics_from_event` is `false`.' unless @metric_name_key
      raise Fluent::ConfigError, '`metric_value_key` is required when `metric_name_key` is set.' unless @metric_value_key
    end

    def format_event(tag, time, record)
      d = {
        host: @host ? @host.(tag, record) : @default_host,
        # From the API reference
        # http://docs.splunk.com/Documentation/Splunk/latest/RESTREF/RESTinput#services.2Fcollector
        # `time` should be a string or unsigned integer.
        # That's why we use the to_string function here.
        time: time.to_f.to_s
        }.tap { |payload|
          if @time
            time_value = @time.(tag, record)
            # if no value is found don't override and use fluentd's time
            if !time_value.nil?
              payload[:time] = time_value
            end
          end

          payload[:index] = @index.(tag, record) if @index
          payload[:source] = @source.(tag, record) if @source
          payload[:sourcetype] = @sourcetype.(tag, record) if @sourcetype

          # delete nil fields otherwise will get formet error from HEC
          %i[host index source sourcetype].each { |f| payload.delete f if payload[f].nil? }

          if @extra_fields
            payload[:fields] = @extra_fields.map { |name, field| [name, record[field]] }.to_h
            payload[:fields].delete_if { |_k,v| v.nil? }
            # if a field is already in indexed fields, then remove it from the original event
            @extra_fields.values.each { |field| record.delete field }
          end
          if formatter = @formatters.find { |f| f.match? tag }
            record = formatter.format(tag, time, record)
          end
          payload[:event] = convert_to_utf8 record
      }
      if d[:event] == "{}"
        log.warn { "Event after formatting was blank, not sending" }
        return ""
      end
      MultiJson.dump(d)
    end

    def format_metric(tag, time, record)
      payload = {
        host: @host ? @host.call(tag, record) : @default_host,
        # From the API reference
        # http://docs.splunk.com/Documentation/Splunk/latest/RESTREF/RESTinput#services.2Fcollector
        # `time` should be a string or unsigned integer.
        # That's why we use `to_s` here.
        time: time.to_f.to_s,
        event: 'metric'
      }.tap do |payload|
        if @time
          time_value = @time.(tag, record)
          # if no value is found don't override and use fluentd's time
          if !time_value.nil?
            payload[:time] = time_value
          end
        end
      end
      payload[:index] = @index.call(tag, record) if @index
      payload[:source] = @source.call(tag, record) if @source
      payload[:sourcetype] = @sourcetype.call(tag, record) if @sourcetype

      unless @metrics_from_event
        fields = {
          metric_name: @metric_name.call(tag, record),
          _value: @metric_value.call(tag, record)
        }

        if @extra_fields
          fields.update @extra_fields.map { |name, field| [name, record[field]] }.to_h
          fields.delete_if { |_k,v| v.nil? }
        else
          fields.update record
        end

        fields.delete_if { |_k,v| v.nil? }

        payload[:fields] = convert_to_utf8 fields

        return MultiJson.dump(payload)
      end

      # when metrics_from_event is true, generate one metric event for each key-value in record
      payloads = record.map do |key, value|
        { fields: { metric_name: key, _value: value } }.merge! payload
      end

      payloads.map!(&MultiJson.method(:dump)).join
    end

    def construct_api
      URI("#{@protocol}://#{@hec_host}:#{@hec_port}/services/collector")
    rescue StandardError
      raise Fluent::ConfigError, "hec_host (#{@hec_host}) and/or hec_port (#{@hec_port}) are invalid."
    end

    def new_connection
      Net::HTTP::Persistent.new.tap do |c|
        c.verify_mode = @insecure_ssl ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
        c.cert = OpenSSL::X509::Certificate.new File.read(@client_cert) if @client_cert
        c.key = OpenSSL::PKey::RSA.new File.read(@client_key) if @client_key
        c.ca_file = @ca_file
        c.ca_path = @ca_path
        c.ciphers = @ssl_ciphers
        c.proxy   = :ENV
        c.idle_timeout = @idle_timeout
        c.read_timeout = @read_timeout
        c.open_timeout = @open_timeout
        c.min_version = OpenSSL::SSL::TLS1_1_VERSION if @require_ssl_min_version

        c.override_headers['Content-Type'] = 'application/json'
        c.override_headers['User-Agent'] = "fluent-plugin-splunk_hec_out/#{VERSION}"
        c.override_headers['Authorization'] = "Splunk #{@hec_token}"
        c.override_headers['__splunk_app_name'] = "#{@app_name}"
        c.override_headers['__splunk_app_version'] = "#{@app_version}"

      end
    end

    def write_to_splunk(chunk)
      post = Net::HTTP::Post.new @api.request_uri
      post.body = chunk.read
      log.debug { "[Sending] Chunk: #{dump_unique_id_hex(chunk.unique_id)}(#{post.body.bytesize}B)." }
      log.trace { "POST #{@api} body=#{post.body}" }

      t1 = Time.now
      response = @conn.request @api, post
      t2 = Time.now

      raise_err = response.code.to_s.start_with?('5') || (!@consume_chunk_on_4xx_errors && response.code.to_s.start_with?('4'))

      # raise Exception to utilize Fluentd output plugin retry mechanism
      raise "Server error (#{response.code}) for POST #{@api}, response: #{response.body}" if raise_err

      # For both success response (2xx) we will consume the chunk.
      if not response.code.start_with?('2')
        log.error "Failed POST to #{@api}, response: #{response.body}"
        log.debug { "Failed request body: #{post.body}" }
      end

      log.debug { "[Response] Chunk: #{dump_unique_id_hex(chunk.unique_id)} Size: #{post.body.bytesize} Response: #{response.inspect} Duration: #{t2 - t1}" }
      process_response(response, post.body)
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
          replace: @non_utf8_replacement_string)
      else
        begin
          input.encode('utf-8')
        rescue EncodingError
          log.error { 'Encountered encoding issues potentially due to non ' \
              'UTF-8 characters. To allow non-UTF-8 characters and ' \
              'replace them with spaces, please set "coerce_to_utf8" ' \
              'to true.' }
          raise
        end
      end
    end
  end
end
