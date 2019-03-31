# frozen_string_literal: true

module HTTP
  module FormData
    # Represents a body part of multipart/form-data request.
    #
    # @example Usage with String
    #
    #  body = "Message"
    #  FormData::Part.new body, :content_type => 'foobar.txt; charset="UTF-8"'
    class Part
      attr_reader :content_type, :filename

      # @param body [#to_s]
      # @param opts [Hash]
      # @option opts [String] :content_type Value of Content-Type header
      # @option opts [String] :filename     Value of filename parameter
      def initialize(body, opts = {})
        @body = body.to_s
        @content_type = opts[:content_type]
        @filename = opts[:filename]
      end

      # Returns content size.
      #
      # @return [Integer]
      def size
        @body.bytesize
      end

      # Returns content of a file of IO.
      #
      # @return [String]
      def to_s
        @body
      end
    end
  end
end
