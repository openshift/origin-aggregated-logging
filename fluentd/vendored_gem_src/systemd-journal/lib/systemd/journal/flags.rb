module Systemd
  class Journal
    # contains a set of constants which maybe bitwise OR-ed together and passed
    # to the Journal constructor.
    # @example
    #   Systemd::Journal.new(flags: Systemd::Journal::Flags::LOCAL_ONLY)
    module Flags
      # Only open journal files generated on the local machine.
      LOCAL_ONLY    = 1
      # Only open non-persistent journal files.
      RUNTIME_ONLY  = 2
      # Only open kernel and system service journal files.
      SYSTEM_ONLY   = 4
    end
  end
end
