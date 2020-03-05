# frozen_string_literal: true

require 'fluent/plugin/out_splunk'
require 'openid_connect'
require 'rack/oauth2'
require 'multi_json'

module Fluent::Plugin
  class SplunkIngestApiOutput < SplunkOutput
    Fluent::Plugin.register_output('splunk_ingest_api', self)

    desc 'Service Client Identifier'
    config_param :service_client_identifier, :string, default: nil

    desc 'Service Client Secret Key'
    config_param :service_client_secret_key, :string, default: nil

    desc 'Token Endpoint'
    config_param :token_endpoint, :string, default: '/token'

    desc 'Token Auth Hostname'
    config_param :ingest_auth_host, :string, default: 'auth.scp.splunk.com'

    desc 'Ingest Api Hostname'
    config_param :ingest_api_host, :string, default: 'api.scp.splunk.com'

    desc 'Ingest API Tenant Name'
    config_param :ingest_api_tenant, :string

    desc 'Ingest API Events Endpoint'
    config_param :ingest_api_events_endpoint, :string, default: '/ingest/v1beta2/events'

    desc 'Debug the HTTP transport'
    config_param :debug_http, :bool, default: false

    def prefer_buffer_processing
      true
    end

    def configure(conf)
      super
    end

    def construct_api
      uri = "https://#{@ingest_api_host}/#{@ingest_api_tenant}#{@ingest_api_events_endpoint}"
      URI(uri)
    rescue StandardError
      raise Fluent::ConfigError, "URI #{uri} is invalid"
    end

    def format(tag, time, record)
      format_event(tag, time, record)
    end

    def format_event(tag, time, record)
      event = prepare_event_payload(tag, time, record)
      # Unsure how to drop a record. So append the empty string
      if event[:body].nil? || event[:body].strip.empty?
        ''
      else
        MultiJson.dump(event) + ','
      end
    end

    def prepare_event_payload(tag, time, record)
      payload = super(tag, time, record)
      payload[:attributes] = payload.delete(:fields) || {}
      payload[:attributes][:index] = payload.delete(:index) if payload[:index]
      payload[:body] = payload.delete(:event)
      payload.delete(:time)
      payload[:timestamp] = (time.to_f * 1000).to_i
      payload[:nanos] = time.nsec / 100_000

      payload
    end

    def process_response(response, request_body)
      super
      if response.code.to_s == '401'
        @conn = new_connection
        raise 'Auth Error recived. New token has been fetched.'
      elsif response.code.to_s == '429'
        raise "Throttle error from server. #{response.body}"
      elsif /INVALID_DATA/.match?(response.body)
        log.error "#{self.class}: POST Body #{request_body}"
      end
    end

    def new_connection
      Rack::OAuth2.debugging = true if @debug_http
      client = OpenIDConnect::Client.new(
        token_endpoint: @token_endpoint,
        identifier: @service_client_identifier,
        secret: @service_client_secret_key,
        redirect_uri: 'http://localhost:8080/', # Not used
        host: @ingest_auth_host,
        scheme: 'https'
      )

      client.access_token!(client_auth_method: 'other')
    end

    def write_to_splunk(chunk)
      log.trace "#{self.class}: In write() with #{chunk.size_of_events} records and #{chunk.bytesize} bytes "
      # ingest API is an array of json objects
      body = "[#{chunk.read.chomp(',')}]"
      @conn ||= new_connection
      response = @conn.post("https://#{@ingest_api_host}/#{@ingest_api_tenant}#{@ingest_api_events_endpoint}", body: body)
      process_response(response, body)
    end
  end
end
