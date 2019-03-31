module Systemd
  class Journal
    module Filterable
      # Filter the journal at a high level.
      # Takes any number of arguments; each argument should be a hash
      # representing a condition to filter based on.  Fields inside the hash
      # will be ANDed together.  Each hash will be ORed with the others.
      # Fields in hashes with Arrays as values are treated as an OR statement,
      # since otherwise they would never match.
      # @example
      #   j = Systemd::Journal.filter(
      #     {_systemd_unit: 'session-4.scope'},
      #     {priority: [4, 6]},
      #     {_exe: '/usr/bin/sshd', priority: 1}
      #   )
      #   # equivalent to
      #   (_systemd_unit == 'session-4.scope') ||
      #   (priority == 4 || priority == 6)     ||
      #   (_exe == '/usr/bin/sshd' && priority == 1)
      def filter(*conditions)
        clear_filters

        last_index = conditions.length - 1

        conditions.each_with_index do |condition, index|
          add_filters(condition)
          add_disjunction unless index == last_index
        end
      end

      # Add a filter to journal, such that only entries where the given filter
      # matches are returned.
      # {#move_next} or {#move_previous} must be invoked after adding a filter
      # before attempting to read from the journal.
      # @param [String] field the column to filter on, e.g. _PID, _EXE.
      # @param [String] value the match to search for, e.g. '/usr/bin/sshd'
      # @return [nil]
      def add_filter(field, value)
        match = "#{field.to_s.upcase}=#{value}"
        rc = Native.sd_journal_add_match(@ptr, match, match.length)
        raise JournalError, rc if rc < 0
      end

      # Add a set of filters to the journal, such that only entries where the
      # given filters match are returned.
      # @param [Hash] filters a set of field/filter value pairs.
      #   If the filter value is an array, each value in the array is added
      #   and entries where the specified field matches any of the values is
      #   returned.
      # @example Filter by PID and EXE
      #   j.add_filters(_pid: 6700, _exe: '/usr/bin/sshd')
      def add_filters(filters)
        filters.each do |field, value|
          Array(value).each { |v| add_filter(field, v) }
        end
      end

      # Add an OR condition to the filter.  All previously added matches
      # will be ORed with the terms following the disjunction.
      # {#move_next} or {#move_previous} must be invoked after adding a match
      # before attempting to read from the journal.
      # @return [nil]
      # @example Filter entries returned using an OR condition
      #   j = Systemd::Journal.new
      #   j.add_filter('PRIORITY', 5)
      #   j.add_disjunction
      #   j.add_filter('_EXE', '/usr/bin/sshd')
      #   while j.move_next
      #     # current_entry is either an sshd event or
      #     # has priority 5
      #   end
      def add_disjunction
        rc = Native.sd_journal_add_disjunction(@ptr)
        raise JournalError, rc if rc < 0
      end

      # Add an AND condition to the filter.  All previously added terms will be
      # ANDed together with terms following the conjunction.
      # {#move_next} or {#move_previous} must be invoked after adding a match
      # before attempting to read from the journal.
      # @return [nil]
      # @example Filter entries returned using an AND condition
      #   j = Systemd::Journal.new
      #   j.add_filter('PRIORITY', 5)
      #   j.add_conjunction
      #   j.add_filter('_EXE', '/usr/bin/sshd')
      #   while j.move_next
      #     # current_entry is an sshd event with priority 5
      #   end
      def add_conjunction
        rc = Native.sd_journal_add_conjunction(@ptr)
        raise JournalError, rc if rc < 0
      end

      # Remove all filters and conjunctions/disjunctions.
      # @return [nil]
      def clear_filters
        Native.sd_journal_flush_matches(@ptr)
      end
    end
  end
end
