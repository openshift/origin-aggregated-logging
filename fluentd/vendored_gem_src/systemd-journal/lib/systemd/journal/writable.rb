require 'systemd/journal/native'
require 'systemd/journal_error'

module Systemd
  class Journal
    # This module provides write access to the systemd Journal, compatible with
    # the systemd-journal.gem by Daniel Mack
    # (https://github.com/zonque/systemd-journal.gem).
    module Writable
      # system is unusable
      LOG_EMERG   = 0
      # action must be taken immediately
      LOG_ALERT   = 1
      # critical conditions
      LOG_CRIT    = 2
      # error conditions
      LOG_ERR     = 3
      # warning conditions
      LOG_WARNING = 4
      # normal but significant condition
      LOG_NOTICE  = 5
      # informational
      LOG_INFO    = 6
      # debug-level messages
      LOG_DEBUG   = 7

      # @private
      def self.included(base)
        base.extend(ClassMethods)
      end

      # methods in this module will be available as class methods on
      #  {Systemd::Journal}
      module ClassMethods
        # Creates a new IO stream which writes newline-seperated messages to
        # the journal.
        # @param identifier [String] this value will be passed as
        #   SYSLOG_IDENTIFIER to the journal.
        # @param priority [Integer] the log level for events writen to this
        #   stream.
        # @param opts [Hash]
        # @option opts [Boolean] :prefix true to enable kernel-style log
        #   priority prefixes
        # @return [IO]
        def log_stream(identifier, priority, opts = {})
          fd = Native.sd_journal_stream_fd(
            identifier,
            priority,
            !opts[:prefix].nil?
          )
          raise JournalError, fd if fd < 0

          IO.new(fd, File::WRONLY, encoding: Encoding::UTF_8)
        end

        # write the value of the c errno constant to the systemd journal in the
        # style of the perror() function.
        # @param [String] message the text to prefix the error message with.
        def perror(message)
          rc = Native.sd_journal_perror(message)
          raise JournalError, rc if rc < 0
        end

        # write a simple message to the systemd journal.
        # @param [Integer] level one of the LOG_* constants defining the
        #   severity of the event.
        # @param [String] message the content of the message to write.
        def print(level, message)
          rc = Native.sd_journal_print(level, message)
          raise JournalError, rc if rc < 0
        end

        # write an event to the systemd journal.
        # @param [Hash] contents the set of key-value pairs defining the event.
        def message(contents)
          items = contents.flat_map do |k, v|
            value = v.to_s.gsub('%', '%%')
            [:string, "#{k.to_s.upcase}=#{value}"]
          end
          # add a null pointer to terminate the varargs
          items += [:string, nil]
          rc = Native.sd_journal_send(*items)
          raise JournalError, rc if rc < 0
        end
      end
    end
  end
end
