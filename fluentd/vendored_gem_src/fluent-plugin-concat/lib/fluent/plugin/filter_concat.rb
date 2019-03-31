require "fluent/plugin/filter"

module Fluent::Plugin
  class ConcatFilter < Filter
    Fluent::Plugin.register_filter("concat", self)

    helpers :timer, :event_emitter

    desc "The key for part of multiline log"
    config_param :key, :string
    desc "The separator of lines"
    config_param :separator, :string, default: "\n"
    desc "The number of lines"
    config_param :n_lines, :integer, default: nil
    desc "The regexp to match beginning of multiline"
    config_param :multiline_start_regexp, :string, default: nil
    desc "The regexp to match ending of multiline"
    config_param :multiline_end_regexp, :string, default: nil
    desc "The regexp to match continuous lines"
    config_param :continuous_line_regexp, :string, default: nil
    desc "The key to determine which stream an event belongs to"
    config_param :stream_identity_key, :string, default: nil
    desc "The interval between data flushes, 0 means disable timeout"
    config_param :flush_interval, :time, default: 60
    desc "The label name to handle timeout"
    config_param :timeout_label, :string, default: nil
    desc "Use timestamp of first record when buffer is flushed"
    config_param :use_first_timestamp, :bool, default: false
    desc "The field name that is the reference to concatenate records"
    config_param :partial_key, :string, default: nil
    desc "The value stored in the field specified by partial_key that represent partial log"
    config_param :partial_value, :string, default: nil
    desc "If true, keep partial_key in concatenated records"
    config_param :keep_partial_key, :bool, default: false

    class TimeoutError < StandardError
    end

    def initialize
      super

      @buffer = Hash.new {|h, k| h[k] = [] }
      @timeout_map_mutex = Thread::Mutex.new
      @timeout_map_mutex.synchronize do
        @timeout_map = Hash.new {|h, k| h[k] = Fluent::Engine.now }
      end
    end

    def configure(conf)
      super

      if @n_lines && (@multiline_start_regexp || @multiline_end_regexp)
        raise Fluent::ConfigError, "n_lines and multiline_start_regexp/multiline_end_regexp are exclusive"
      end
      if @n_lines.nil? && @multiline_start_regexp.nil? && @multiline_end_regexp.nil? && @partial_key.nil?
        raise Fluent::ConfigError, "Either n_lines or multiline_start_regexp or multiline_end_regexp is required"
      end
      if @partial_key && @n_lines
        raise Fluent::ConfigError, "partial_key and n_lines are exclusive"
      end
      if @partial_key && (@multiline_start_regexp || @multiline_end_regexp)
        raise Fluent::ConfigError, "partial_key and multiline_start_regexp/multiline_end_regexp are exclusive"
      end
      if @partial_key && @partial_value.nil?
        raise Fluent::ConfigError, "partial_value is required when partial_key is specified"
      end

      @mode = nil
      case
      when @n_lines
        @mode = :line
      when @partial_key
        @mode = :partial
      when @multiline_start_regexp || @multiline_end_regexp
        @mode = :regexp
        if @multiline_start_regexp
          @multiline_start_regexp = Regexp.compile(@multiline_start_regexp[1..-2])
        end
        if @multiline_end_regexp
          @multiline_end_regexp = Regexp.compile(@multiline_end_regexp[1..-2])
        end
        if @continuous_line_regexp
          @continuous_line_regexp = Regexp.compile(@continuous_line_regexp[1..-2])
        end
      end
    end

    def start
      super
      @finished = false
      timer_execute(:filter_concat_timer, 1, &method(:on_timer))
    end

    def shutdown
      @finished = true
      flush_remaining_buffer
      super
    end

    def filter_stream(tag, es)
      new_es = Fluent::MultiEventStream.new
      es.each do |time, record|
        if /\Afluent\.(?:trace|debug|info|warn|error|fatal)\z/ =~ tag
          new_es.add(time, record)
          next
        end
        unless record.key?(@key)
          new_es.add(time, record)
          next
        end
        begin
          flushed_es = process(tag, time, record)
          unless flushed_es.empty?
            flushed_es.each do |_time, new_record|
              time = _time if @use_first_timestamp
              merged_record = record.merge(new_record)
              merged_record.delete(@partial_key) unless @keep_partial_key
              new_es.add(time, merged_record)
            end
          end
        rescue => e
          router.emit_error_event(tag, time, record, e)
        end
      end
      new_es
    end

    private

    def on_timer
      return if @flush_interval <= 0
      return if @finished
      flush_timeout_buffer
    rescue => e
      log.error "failed to flush timeout buffer", error: e
    end

    def process(tag, time, record)
      if @stream_identity_key
        stream_identity = "#{tag}:#{record[@stream_identity_key]}"
      else
        stream_identity = "#{tag}:default"
      end
      @timeout_map_mutex.synchronize do
        @timeout_map[stream_identity] = Fluent::Engine.now
      end
      case @mode
      when :line
        process_line(stream_identity, tag, time, record)
      when :partial
        process_partial(stream_identity, tag, time, record)
      when :regexp
        process_regexp(stream_identity, tag, time, record)
      end
    end

    def process_line(stream_identity, tag, time, record)
      new_es = Fluent::MultiEventStream.new
      @buffer[stream_identity] << [tag, time, record]
      if @buffer[stream_identity].size >= @n_lines
        new_time, new_record = flush_buffer(stream_identity)
        time = new_time if @use_first_timestamp
        new_es.add(time, new_record)
      end
      new_es
    end

    def process_partial(stream_identity, tag, time, record)
      new_es = Fluent::MultiEventStream.new
      @buffer[stream_identity] << [tag, time, record]
      unless @partial_value == record[@partial_key]
        new_time, new_record = flush_buffer(stream_identity)
        time = new_time if @use_first_timestamp
        new_record.delete(@partial_key)
        new_es.add(time, new_record)
      end
      new_es
    end

    def process_regexp(stream_identity, tag, time, record)
      new_es = Fluent::MultiEventStream.new
      case
      when firstline?(record[@key])
        if @buffer[stream_identity].empty?
          @buffer[stream_identity] << [tag, time, record]
          if lastline?(record[@key])
            new_time, new_record = flush_buffer(stream_identity)
            time = new_time if @use_first_timestamp
            new_es.add(time, new_record)
          end
        else
          new_time, new_record = flush_buffer(stream_identity, [tag, time, record])
          time = new_time if @use_first_timestamp
          new_es.add(time, new_record)
          if lastline?(record[@key])
            new_time, new_record = flush_buffer(stream_identity)
            time = new_time if @use_first_timestamp
            new_es.add(time, new_record)
          end
          return new_es
        end
      when lastline?(record[@key])
        @buffer[stream_identity] << [tag, time, record]
        new_time, new_record = flush_buffer(stream_identity)
        time = new_time if @use_first_timestamp
        new_es.add(time, new_record)
        return new_es
      else
        if @buffer[stream_identity].empty?
          if !@multiline_start_regexp
            @buffer[stream_identity] << [tag, time, record]
          else
            new_es.add(time, record)
            return new_es
          end
        else
          if continuous_line?(record[@key])
            # Continuation of the previous line
            @buffer[stream_identity] << [tag, time, record]
          else
            new_time, new_record = flush_buffer(stream_identity)
            time = new_time if @use_first_timestamp
            new_es.add(time, new_record)
            new_es.add(time, record)
          end
        end
      end
      new_es
    end

    def firstline?(text)
      @multiline_start_regexp && !!@multiline_start_regexp.match(text)
    end

    def lastline?(text)
      @multiline_end_regexp && !!@multiline_end_regexp.match(text)
    end

    def continuous_line?(text)
      if @continuous_line_regexp
        !!@continuous_line_regexp.match(text)
      else
        true
      end
    end

    def flush_buffer(stream_identity, new_element = nil)
      lines = @buffer[stream_identity].map {|_tag, _time, record| record[@key] }
      _tag, time, first_record = @buffer[stream_identity].first
      new_record = {
        @key => lines.join(@separator)
      }
      @buffer[stream_identity] = []
      @buffer[stream_identity] << new_element if new_element
      [time, first_record.merge(new_record)]
    end

    def flush_timeout_buffer
      now = Fluent::Engine.now
      timeout_stream_identities = []
      @timeout_map_mutex.synchronize do
        @timeout_map.each do |stream_identity, previous_timestamp|
          next if @flush_interval > (now - previous_timestamp)
          next if @buffer[stream_identity].empty?
          time, flushed_record = flush_buffer(stream_identity)
          timeout_stream_identities << stream_identity
          tag = stream_identity.split(":").first
          message = "Timeout flush: #{stream_identity}"
          handle_timeout_error(tag, @use_first_timestamp ? time : now, flushed_record, message)
          log.info(message)
        end
        @timeout_map.reject! do |stream_identity, _|
          timeout_stream_identities.include?(stream_identity)
        end
      end
    end

    def flush_remaining_buffer
      @buffer.each do |stream_identity, elements|
        next if elements.empty?

        lines = elements.map {|_tag, _time, record| record[@key] }
        new_record = {
          @key => lines.join(@separator)
        }
        tag, time, record = elements.first
        message = "Flush remaining buffer: #{stream_identity}"
        handle_timeout_error(tag, time, record.merge(new_record), message)
        log.info(message)
      end
      @buffer.clear
    end

    def handle_timeout_error(tag, time, record, message)
      if @timeout_label
        event_router = event_emitter_router(@timeout_label)
        event_router.emit(tag, time, record)
      else
        router.emit_error_event(tag, time, record, TimeoutError.new(message))
      end
    end
  end
end
