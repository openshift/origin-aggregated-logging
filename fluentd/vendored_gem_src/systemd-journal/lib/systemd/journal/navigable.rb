module Systemd
  class Journal
    module Navigable
      # returns a string representing the current read position.
      # This string can be passed to {#seek} or {#cursor?}.
      # @return [String] a cursor token.
      def cursor
        out_ptr = FFI::MemoryPointer.new(:pointer, 1)
        if (rc = Native.sd_journal_get_cursor(@ptr, out_ptr)) < 0
          raise JournalError, rc
        end

        Journal.read_and_free_outstr(out_ptr.read_pointer)
      end

      # Check if the read position is currently at the entry represented by the
      # provided cursor value.
      # @param c [String] a cursor token returned from {#cursor}.
      # @return [Boolean] True if current entry is the one represented by the
      # provided cursor, False otherwise.
      def cursor?(c)
        if (rc = Native.sd_journal_test_cursor(@ptr, c)) < 0
          raise JournalError, rc
        end

        rc > 0
      end

      # Move the read pointer by `offset` entries.
      # @param [Integer] offset how many entries to move the read pointer by.
      #   If this value is positive, the read pointer moves forward. Otherwise,
      #   it moves backwards.  Defaults to moving forward one entry.
      # @return [Integer] number of entries the read pointer actually moved.
      def move(offset = 1)
        offset > 0 ? move_next_skip(offset) : move_previous_skip(-offset)
      end

      # Move the read pointer to the next entry in the journal.
      # @return [Boolean] True if moving to the next entry was successful.
      # @return [Boolean] False if unable to move to the next entry, indicating
      #   that the pointer has reached the end of the journal.
      def move_next
        rc = Native.sd_journal_next(@ptr)
        raise JournalError, rc if rc < 0
        rc > 0
      end

      # Move the read pointer forward by `amount` entries.
      # @return [Integer] actual number of entries by which the read pointer
      #   moved. If this number is less than the requested amount, the read
      #   pointer has reached the end of the journal.
      def move_next_skip(amount)
        rc = Native.sd_journal_next_skip(@ptr, amount)
        raise JournalError, rc if rc < 0
        rc
      end

      # Move the read pointer to the previous entry in the journal.
      # @return [Boolean] True if moving to the previous entry was successful.
      # @return [Boolean] False if unable to move to the previous entry,
      #   indicating that the pointer has reached the beginning of the journal.
      def move_previous
        rc = Native.sd_journal_previous(@ptr)
        raise JournalError, rc if rc < 0
        rc > 0
      end

      # Move the read pointer backwards by `amount` entries.
      # @return [Integer] actual number of entries by which the read pointer
      #   was moved.  If this number is less than the requested amount, the
      #   read pointer has reached the beginning of the journal.
      def move_previous_skip(amount)
        rc = Native.sd_journal_previous_skip(@ptr, amount)
        raise JournalError, rc if rc < 0
        rc
      end

      # Seek to a position in the journal.
      # Note: after seeking, you must call {#move_next} or {#move_previous}
      #   before you can call {#read_field} or {#current_entry}.
      #   When calling `seek(:tail)` the read pointer is positioned _after_
      #   the last entry in the journal -- thus you should use `move_previous`.
      #   Otherwise, use `move_next`.
      #
      # @param [Symbol, Time] whence one of :head, :tail, or a Time instance.
      #   `:head` (or `:start`) will seek to the beginning of the journal.
      #   `:tail` (or `:end`) will seek to the end of the journal. When a
      #   `Time` is provided, seek to the journal entry logged closest to that
      #   time. When a String is provided, assume it is a cursor from {#cursor}
      #   and seek to that entry.
      # @return [True]
      # @example Read last journal entry
      #   j = Systemd::Joural.new
      #   j.seek(:tail)
      #   j.move_previous
      #   puts j.current_entry
      def seek(where)
        rc = case
             when [:head, :start].include?(where)
               Native.sd_journal_seek_head(@ptr)
             when [:tail, :end].include?(where)
               Native.sd_journal_seek_tail(@ptr)
             when where.is_a?(Time)
               Native.sd_journal_seek_realtime_usec(
                 @ptr,
                 where.to_i * 1_000_000
               )
             when where.is_a?(String)
               Native.sd_journal_seek_cursor(@ptr, where)
             else
               raise ArgumentError, "Unknown seek type: #{where.class}"
             end

        raise JournalError, rc if rc < 0

        true
      end
    end
  end
end
