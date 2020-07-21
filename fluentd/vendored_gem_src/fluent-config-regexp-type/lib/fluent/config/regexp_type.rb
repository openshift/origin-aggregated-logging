require "fluent/config"
require "fluent/config/types"

unless Fluent::Config.respond_to?(:regexp_value)
  module Fluent
    module Config
      def self.regexp_value(str)
        return nil unless str
        return Regexp.compile(str) unless str.start_with?("/")
        right_slash_position = str.rindex("/")
        options = str[(right_slash_position + 1)..-1]
        option = 0
        option |= Regexp::IGNORECASE if options.include?("i")
        option |= Regexp::MULTILINE if options.include?("m")
        Regexp.compile(str[1...right_slash_position], option)
      end
      REGEXP_TYPE = Proc.new { |val, opts| Config.regexp_value(val) }
    end
  end
  Fluent::Configurable.register_type(:regexp, Fluent::Config::REGEXP_TYPE)
end
