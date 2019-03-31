# frozen_string_literal: true

module HTTP
  module FormData
    class Multipart
      # Utility class to represent multi-part chunks
      class Param
        # @param [#to_s] name
        # @param [FormData::File, FormData::Part, #to_s] value
        def initialize(name, value)
          @name = name.to_s

          @part =
            if value.is_a?(FormData::Part)
              value
            else
              FormData::Part.new(value)
            end

          parameters = { :name => @name }
          parameters[:filename] = @part.filename if @part.filename
          parameters = parameters.map { |k, v| "#{k}=#{v.inspect}" }.join("; ")

          @header = "Content-Disposition: form-data; #{parameters}"

          return unless @part.content_type

          @header += "#{CRLF}Content-Type: #{@part.content_type}"
        end

        # Returns body part with headers and data.
        #
        # @example With {FormData::File} value
        #
        #   Content-Disposition: form-data; name="avatar"; filename="avatar.png"
        #   Content-Type: application/octet-stream
        #
        #   ...data of avatar.png...
        #
        # @example With non-{FormData::File} value
        #
        #   Content-Disposition: form-data; name="username"
        #
        #   ixti
        #
        # @return [String]
        def to_s
          "#{@header}#{CRLF * 2}#{@part}"
        end

        # Calculates size of a part (headers + body).
        #
        # @return [Integer]
        def size
          @header.bytesize + (CRLF.bytesize * 2) + @part.size
        end

        # Flattens given `data` Hash into an array of `Param`'s.
        # Nested array are unwinded.
        # Behavior is similar to `URL.encode_www_form`.
        #
        # @param [Hash] data
        # @return [Array<FormData::MultiPart::Param>]
        def self.coerce(data)
          params = []

          data.each do |name, values|
            Array(values).each do |value|
              params << new(name, value)
            end
          end

          params
        end
      end
    end
  end
end
