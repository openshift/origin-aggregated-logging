# frozen_string_literal: true

require "securerandom"

require "http/form_data/multipart/param"

module HTTP
  module FormData
    # `multipart/form-data` form data.
    class Multipart
      # @param [#to_h, Hash] data form data key-value Hash
      def initialize(data)
        @parts          = Param.coerce FormData.ensure_hash data
        @boundary       = (Array.new(21, "-") << SecureRandom.hex(21)).join("")
        @content_length = nil
      end

      # Returns content to be used for HTTP request body.
      #
      # @return [String]
      def to_s
        head + @parts.map(&:to_s).join(glue) + tail
      end

      # Returns MIME type to be used for HTTP request `Content-Type` header.
      #
      # @return [String]
      def content_type
        "multipart/form-data; boundary=#{@boundary}"
      end

      # Returns form data content size to be used for HTTP request
      # `Content-Length` header.
      #
      # @return [Integer]
      def content_length
        unless @content_length
          @content_length  = head.bytesize + tail.bytesize
          @content_length += @parts.map(&:size).reduce(:+)
          @content_length += (glue.bytesize * (@parts.count - 1))
        end

        @content_length
      end

      private

      # @return [String]
      def head
        @head ||= "--#{@boundary}#{CRLF}"
      end

      # @return [String]
      def glue
        @glue ||= "#{CRLF}--#{@boundary}#{CRLF}"
      end

      # @return [String]
      def tail
        @tail ||= "#{CRLF}--#{@boundary}--"
      end
    end
  end
end
