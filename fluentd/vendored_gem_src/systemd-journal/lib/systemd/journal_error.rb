require 'ffi'

module Systemd
  # This execption is raised whenever a sd_journal_* call returns an error.
  class JournalError < StandardError
    # Returns the (positive) error number.
    attr_reader :code

    # Instantiate a new JournalError based on the specified return code.
    # `message` will be filled in by calling `strerror()` with the provided
    # return code.
    def initialize(code)
      @code = -code
      super(LIBC.strerror(@code))
    end

    # FFI wrapper for the C standard library to pull in `strerror`.
    # @private
    module LIBC
      extend FFI::Library
      ffi_lib FFI::Library::LIBC

      attach_function :strerror, [:int], :string
    end
  end
end
