require 'ffi'

module Systemd
  # Provides access to the 128-bit IDs for various items in the systemd
  # ecosystem, such as the machine id and boot id.
  module Id128
    # Get the 128-bit hex string identifying the current machine.
    # Can be used to filter a journal to show only messages originating
    # from this machine.
    # @example Filter journal to the current machine.
    #   j = Systemd::Journal.new
    #   j.filter(_machine_id: Systemd::Id128.machine_id)
    # @return [String] 128-bit hex string representing the current machine.
    def self.machine_id
      @machine_id ||= read_id128(:sd_id128_get_machine)
    end

    # Get the 128-bit hex string identifying the current system's current boot.
    # Can be used to filter a journal to show only messages originating from
    # the current boot.
    # @example Filter journal to the current boot.
    #   j = Systemd::Journal.new
    #   j.filter(_boot_id: Systemd::Id128.boot_id)
    # @return [String] 128-bit hex string representing the current boot.
    def self.boot_id
      @boot_id ||= read_id128(:sd_id128_get_boot)
    end

    # Get a random 128-bit hex string.
    # @return [String] 128-bit random hex string.
    def self.random
      read_id128(:sd_id128_randomize)
    end

    private

    def self.read_id128(func)
      ptr = FFI::MemoryPointer.new(Native::Id128, 1)
      rc = Native.send(func, ptr)
      raise JournalError, rc if rc < 0
      Native::Id128.new(ptr).to_s
    end

    # providing bindings to the systemd-id128 library.
    module Native
      require 'ffi'
      extend FFI::Library
      ffi_lib %w( libsystemd.so.0       libsystemd.so
                  libsystemd-id128.so.0 libsystemd-id128.so )

      attach_function :sd_id128_get_machine, [:pointer], :int
      attach_function :sd_id128_get_boot,    [:pointer], :int
      attach_function :sd_id128_randomize,   [:pointer], :int

      # @private
      class Id128 < FFI::Union
        layout :bytes,  [:uint8, 16],
               :dwords, [:uint32, 4],
               :qwords, [:uint64, 2]

        def to_s
          format('%02x' * 16, *self[:bytes].to_a)
        end

        def self.from_s(str)
          r = Id128.new
          [str].pack('H*').bytes.each_with_index do |b, i|
            r[:bytes][i] = b
          end

          r
        end
      end
    end
  end
end
