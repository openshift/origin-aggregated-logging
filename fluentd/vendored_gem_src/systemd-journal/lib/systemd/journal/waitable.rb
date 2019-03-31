module Systemd
  class Journal
    module Waitable
      IS_JRUBY = (RUBY_ENGINE == 'jruby')

      # Block until the journal is changed.
      # @param timeout_usec [Integer] maximum number of microseconds to wait
      #   or `-1` to wait indefinitely.
      # @example Wait for an event for a maximum of 3 seconds
      #   j = Systemd::Journal.new
      #   j.seek(:tail)
      #   if j.wait(3 * 1_000_000)
      #     # event occurred
      #   end
      # @return [Nil] the wait time was reached (no events occured).
      # @return [Symbol] :append new entries were appened to the journal.
      # @return [Symbol] :invalidate journal files were added/removed/rotated.
      def wait(timeout_usec = -1, opts = {})
        if opts[:select] && !IS_JRUBY
          wait_select(timeout_usec)
        else
          rc = Native.sd_journal_wait(@ptr, timeout_usec)
          raise JournalError, rc if rc.is_a?(Integer) && rc < 0
          rc == :nop ? nil : rc
        end
      end

      # Determine if calls to {#wait} with `select: true` will reliably wake
      # when a change occurs. If false, there might be some (unknown) latency
      # involved between when an change occurs and when {#wait} returns.
      # @return [Boolean]
      def wait_select_reliable?
        Native.sd_journal_reliable_fd(@ptr) > 0
      end

      # Block and wait for new entries to be appended to the journal. When new
      # entries are written, yields them in turn.  Note that this function does
      # not automatically seek to the end of the journal prior to waiting.
      # This method Does not return.
      # @example Print out events as they happen
      #   j = Systemd::Journal.new
      #   j.seek(:tail)
      #   j.watch do |event|
      #     puts event.message
      #   end
      def watch
        loop { (yield current_entry while move_next) if wait }
      end

      private

      def wait_select(timeout_usec)
        timeout_sec = (timeout_usec == -1 ? nil : timeout_usec / 1e6)
        r, *_ = IO.select([io_object], [], [], timeout_sec)
        r ? reason_for_wakeup : nil
      end

      def io_object
        @io ||= IO.new(file_descriptor, autoclose: false)
      end

      def file_descriptor
        fd = Native.sd_journal_get_fd(@ptr)
        raise JournalError, fd if fd < 0
        fd
      end

      def reason_for_wakeup
        rc = Native.sd_journal_process(@ptr)
        raise JournalError, rc if rc.is_a?(Integer) && rc < 0
        rc == :nop ? nil : rc
      end
    end
  end
end
