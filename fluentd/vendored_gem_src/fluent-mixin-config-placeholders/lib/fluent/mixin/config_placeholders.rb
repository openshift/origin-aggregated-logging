require 'fluent/config'
require 'socket'

module Fluent
  module Mixin
    module ConfigPlaceholders
      attr_accessor :hostname

      PLACEHOLDERS_DEFAULT = [ :dollar, :underscore ] # and :percent

      # ${hostname}, %{hostname}, __HOSTNAME__

      # ${uuid} or ${uuid:random} , %{uuid} or %{uuid:random} __UUID__ or __UUID_RANDOM__
      # UUIDTools::UUID.random_create
      # => #<UUID:0x19013a UUID:984265dc-4200-4f02-ae70-fe4f48964159>

      # ${uuid:hostname} , %{uuid:hostname} , __UUID_HOSTNAME__
      # UUIDTools::UUID.sha1_create(UUIDTools::UUID_DNS_NAMESPACE, "www.widgets.com")
      # => #<UUID:0x2a0116 UUID:21f7f8de-8051-5b89-8680-0195ef798b6a>

      # ${uuid:timestamp} , %{uuid:timestamp} , __UUID_TIMESTAMP__
      # UUIDTools::UUID.timestamp_create
      # => #<UUID:0x2adfdc UUID:64a5189c-25b3-11da-a97b-00c04fd430c8>

      def uuid_random
        require 'uuidtools'
        UUIDTools::UUID.random_create.to_s
      end

      def uuid_hostname(hostname)
        require 'uuidtools'
        UUIDTools::UUID.sha1_create(UUIDTools::UUID_DNS_NAMESPACE, hostname).to_s
      end

      def uuid_timestamp
        require 'uuidtools'
        UUIDTools::UUID.timestamp_create.to_s
      end

      def replace(map, value)
        map.reduce(value){|r,p| r.gsub(p[0], p[1].call())}
      end

      def has_replace_pattern?(value)
        value =~ /\$\{(?:hostname|uuid:[a-z]+)\}/ ||
          value =~ /\%\{(?:hostname|uuid:[a-z]+)\}/ ||
          value =~ /__(?:HOSTNAME|UUID_[A-Z]+)__/
      end

      def configure(conf)
        # Element#has_key? inserts key name into 'used' list, so we should not use that method...
        hostname = if conf.keys.include?('hostname') && has_replace_pattern?( conf.fetch('hostname') )
                     Socket.gethostname
                   elsif conf.keys.include?('hostname')
                     conf['hostname']
                   else
                     Socket.gethostname
                   end

        placeholders = self.respond_to?(:placeholders) ? self.placeholders : PLACEHOLDERS_DEFAULT

        mapping = {}

        placeholders.each do |p|
          case p
          when :dollar
            mapping.update({
                '${hostname}'       => lambda{ hostname },
                '${uuid}'           => lambda{ uuid_random() },
                '${uuid:random}'    => lambda{ uuid_random() },
                '${uuid:hostname}'  => lambda{ uuid_hostname(hostname) },
                '${uuid:timestamp}' => lambda{ uuid_timestamp() },
              })
          when :percent
            mapping.update({
                '%{hostname}'       => lambda{ hostname },
                '%{uuid}'           => lambda{ uuid_random() },
                '%{uuid:random}'    => lambda{ uuid_random() },
                '%{uuid:hostname}'  => lambda{ uuid_hostname(hostname) },
                '%{uuid:timestamp}' => lambda{ uuid_timestamp() },
              })
          when :underscore
            mapping.update({
                '__HOSTNAME__'       => lambda{ hostname },
                '__UUID__'           => lambda{ uuid_random() },
                '__UUID_RANDOM__'    => lambda{ uuid_random() },
                '__UUID_HOSTNAME__'  => lambda{ uuid_hostname(hostname) },
                '__UUID_TIMESTAMP__' => lambda{ uuid_timestamp() },
              })
          else
            raise ArgumentError, "unknown placeholder format: #{p}"
          end
        end

        check_element = ->(map, c) {
          c.arg = replace(map, c.arg)
          c.keys.each do |k|
            v = c.fetch(k, nil)
            if v and v.is_a? String
              c[k] = replace(map, v)
            end
          end
          c.elements.each{|e| check_element.call(map,e)}
        }
        check_element.call(mapping,conf)

        super
      end

    end
  end
end
