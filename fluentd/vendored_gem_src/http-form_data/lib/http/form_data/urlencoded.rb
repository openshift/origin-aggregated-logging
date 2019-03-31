# frozen_string_literal: true

require "uri"

module HTTP
  module FormData
    # `application/x-www-form-urlencoded` form data.
    class Urlencoded
      # @param [#to_h, Hash] data form data key-value Hash
      def initialize(data)
        @data = FormData.ensure_hash data
      end

      # Returns content to be used for HTTP request body.
      #
      # @return [String]
      def to_s
        ::URI.encode_www_form @data
      end

      # Returns MIME type to be used for HTTP request `Content-Type` header.
      #
      # @return [String]
      def content_type
        "application/x-www-form-urlencoded"
      end

      # Returns form data content size to be used for HTTP request
      # `Content-Length` header.
      #
      # @return [Integer]
      def content_length
        to_s.bytesize
      end
    end
  end
end
