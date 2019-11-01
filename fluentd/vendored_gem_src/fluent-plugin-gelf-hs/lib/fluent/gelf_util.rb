# encoding=utf-8
module Fluent
  module GelfUtil

    require 'gelf'

    def make_gelfentry(tag,time,record, conf = {})
      gelfentry = { '_tag' => tag }
      if defined? Fluent::EventTime and time.is_a? Fluent::EventTime then
        gelfentry['timestamp'] = time.sec + (time.nsec.to_f/1000000000).round(3)
      else
        gelfentry['timestamp'] = time
      end

      record.each_pair do |k,v|
        case k
        when 'host' then
          if conf[:use_record_host] then
            gelfentry['host'] = v
          else
            gelfentry['_host'] = v
          end
        when 'level' then
          case v.to_s.downcase[0]
          # emergency and alert aren't supported by gelf-rb
          when "0" then
            gelfentry['level'] = GELF::UNKNOWN
          when "1", "a" then
            gelfentry['level'] = GELF::UNKNOWN
          when "2", "c" then
            gelfentry['level'] = GELF::FATAL
          when "3" then
            gelfentry['level'] = GELF::ERROR
          when "4", "w" then
            gelfentry['level'] = GELF::WARN
          # gelf-rb also skips notice
          when "5", "n" then
            gelfentry['level'] = GELF::INFO
          when "6", "i" then
            gelfentry['level'] = GELF::INFO
          when "7", "d" then
            gelfentry['level'] = GELF::DEBUG
          when "e" then
            if v.to_s.length >= 2 and v.to_s.downcase[1] != "r" then
              gelfentry['level'] = GELF::UNKNOWN
            else
              gelfentry['level'] = GELF::ERROR
            end
          else
            gelfentry['_level'] = v
          end
        when 'msec' then
          # msec must be three digits (leading/trailing zeroes)
          if conf[:add_msec_time] then
            gelfentry['timestamp'] = "#{time.to_s}.#{v}".to_f
          else
            gelfentry['_msec'] = v
          end
        when 'short_message', 'full_message', 'facility', 'line', 'file' then
          gelfentry[k] = v
        else
          if !k.start_with?('_')
            gelfentry['_'+k] = v
          else
            gelfentry[k] = v
          end
        end
      end

      if !gelfentry.key?('short_message') or gelfentry['short_message'].to_s.empty? then
        # allow other non-empty fields to masquerade as the short_message if it is unset
        if gelfentry.key?('_message') and !gelfentry['_message'].to_s.empty? then
          gelfentry['short_message'] = gelfentry.delete('_message')
        elsif gelfentry.key?('_msg') and !gelfentry['_msg'].to_s.empty? then
          gelfentry['short_message'] = gelfentry.delete('_msg')
        elsif gelfentry.key?('_log') and !gelfentry['_log'].to_s.empty? then
          gelfentry['short_message'] = gelfentry.delete('_log')
        elsif gelfentry.key?('_record') and !gelfentry['_record'].to_s.empty? then
          gelfentry['short_message'] = gelfentry.delete('_record')
        else
          # we must have a short_message, so provide placeholder
          gelfentry['short_message'] = '(no message)'
        end
      end

      # I realize the nulls are will be treated as unset keys, but it does
      # tend to make for larger files and data transmissions.
      return gelfentry.delete_if{ |k,v| v.nil? }

    end

    def make_json(gelfentry,conf)
      gelfentry['version'] = '1.0'

      gelfentry.each_pair  do |k,v|
        if v.is_a?(String)
          gelfentry[k] = v.force_encoding('UTF-8')
        end
      end

      gelfentry.to_json + ( conf.is_a?(Hash) and conf.key?(:record_separator) ? conf[:record_separator] : "\0" )
    end
  end
end
