require 'systemd/id128'

module Systemd
  class Journal
    # Provides the FFI bindings to the native `libsystemd-journal` shared
    # library.
    module Native
      # rubocop:disable LineLength
      require 'ffi'
      extend FFI::Library
      ffi_lib %w( libsystemd.so.0         libsystemd.so
                  libsystemd-journal.so.0 libsystemd-journal.so)

      @has_open_container = true

      def self.open_container?
        @has_open_container
      end

      # setup/teardown
      attach_function :sd_journal_open,           [:pointer, :int], :int
      attach_function :sd_journal_open_directory, [:pointer, :string, :int], :int
      attach_function :sd_journal_close,          [:pointer], :void

      attach_function :sd_journal_open_files,     [:pointer, :pointer, :int], :int

      # not available in 208
      begin
        attach_function :sd_journal_open_container, [:pointer, :string, :int], :int
      rescue FFI::NotFoundError
        @has_open_container = false
      end

      # navigation
      attach_function :sd_journal_next,          [:pointer], :int
      attach_function :sd_journal_next_skip,     [:pointer, :uint64], :int
      attach_function :sd_journal_previous,      [:pointer], :int
      attach_function :sd_journal_previous_skip, [:pointer, :uint64], :int

      attach_function :sd_journal_seek_head,          [:pointer], :int
      attach_function :sd_journal_seek_tail,          [:pointer], :int
      attach_function :sd_journal_seek_realtime_usec, [:pointer, :uint64], :int

      attach_function :sd_journal_get_cursor,  [:pointer, :pointer], :int
      attach_function :sd_journal_seek_cursor, [:pointer, :string],  :int
      attach_function :sd_journal_test_cursor, [:pointer, :string],  :int

      # data reading
      attach_function :sd_journal_get_data,       [:pointer, :string, :pointer, :pointer], :int
      attach_function :sd_journal_restart_data,   [:pointer], :void
      attach_function :sd_journal_enumerate_data, [:pointer, :pointer, :pointer], :int
      attach_function :sd_journal_get_catalog,    [:pointer, :pointer], :int
      attach_function :sd_journal_get_catalog_for_message_id, [Systemd::Id128::Native::Id128.by_value, :pointer], :int

      attach_function :sd_journal_get_realtime_usec,  [:pointer, :pointer], :int
      attach_function :sd_journal_get_monotonic_usec, [:pointer, :pointer, :pointer], :int

      attach_function :sd_journal_get_data_threshold, [:pointer, :pointer], :int
      attach_function :sd_journal_set_data_threshold, [:pointer, :size_t],  :int

      # querying
      attach_function :sd_journal_query_unique,     [:pointer, :string], :int
      attach_function :sd_journal_enumerate_unique, [:pointer, :pointer, :pointer], :int
      attach_function :sd_journal_restart_unique,   [:pointer], :void

      # event notification
      enum :wake_reason, [:nop, :append, :invalidate]
      attach_function :sd_journal_wait,        [:pointer, :uint64], :wake_reason, blocking: true
      attach_function :sd_journal_get_fd,      [:pointer], :int
      attach_function :sd_journal_process,     [:pointer], :wake_reason
      attach_function :sd_journal_reliable_fd, [:pointer], :int

      # filtering
      attach_function :sd_journal_add_match,       [:pointer, :string, :size_t], :int
      attach_function :sd_journal_flush_matches,   [:pointer], :void
      attach_function :sd_journal_add_disjunction, [:pointer], :int
      attach_function :sd_journal_add_conjunction, [:pointer], :int

      # writing
      attach_function :sd_journal_print,  [:int, :string], :int
      attach_function :sd_journal_send,   [:varargs], :int
      attach_function :sd_journal_perror, [:string], :int
      attach_function :sd_journal_stream_fd, [:string, :int, :bool], :int

      # misc
      attach_function :sd_journal_get_usage, [:pointer, :pointer], :int
    end
  end

  # @private
  module LibC
    require 'ffi'
    extend FFI::Library
    ffi_lib FFI::Library::LIBC

    attach_function :free, [:pointer], :void
  end
end
