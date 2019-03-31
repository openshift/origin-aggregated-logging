module Systemd
  # Represents a single entry in the Journal.
  class JournalEntry
    include Enumerable

    attr_reader :fields

    # Create a new JournalEntry from the given entry hash. You probably don't
    # need to construct this yourself; instead instances are returned from
    # {Systemd::Journal} methods such as {Systemd::Journal#current_entry}.
    # @param [Hash] entry a hash containing all the key-value pairs associated
    #   with a given journal entry.
    def initialize(entry, context = {})
      inspect = []
      @entry  = entry
      @ctx    = context
      @fields = entry.map do |key, value|
        name = key.downcase.to_sym
        define_singleton_method(name) { value } unless respond_to?(name)

        inspect.push("#{name}: '#{value}'")
        name
      end
      @inspect = inspect.join(', ')
    end

    # Returns the wall-clock time that this entry was received by the journal.
    # @return [Time]
    def realtime_timestamp
      return nil unless @ctx.key?(:realtime_ts)
      @realtime_timestamp ||= Time.at(0, @ctx[:realtime_ts])
    end

    # Returns the monotonic time (time since boot) that this entry was received
    # by the journal.  This should be associated with a boot_id.
    # @return [Time]
    def monotonic_timestamp
      return nil unless @ctx.key?(:monotonic_ts)
      @monotonic_timestamp ||= Time.at(0, @ctx[:monotonic_ts].first)
    end

    # @private
    def method_missing(m, *args)
      # not all journal entries will have all fields.  don't raise an error
      # unless the user passed arguments.
      super(m, *args) unless args.empty?
    end

    # Get the value of a given field in the entry, or nil if it doesn't exist
    # @param [String] the field name for which to look up the value. Can be a
    #   symbol or string, case insensitive.
    # @return [String] the value for the given field, or nil if not found.
    def [](key)
      @entry[key] || @entry[key.to_s.upcase]
    end

    # Yields each field name and value pair to the provided block.
    # If no block is given, returns an enumerator.
    # @return [Enumerator]
    def each
      return to_enum(:each) unless block_given?
      @entry.each { |key, value| yield [key, value] }
    end

    # Returns the catalog message that this Journal Entry references, if any.
    # @option opts [Boolean] :replace set to false to not replace placeholder
    #   strings in the catalog with the associated values in this Journal Entry.
    #   defaults to true.
    # @return [String] the catalog provided message for this Journal Entry, or
    #   nil if non exists.
    def catalog(opts = {})
      return nil unless catalog?

      opts[:replace] = true unless opts.key?(:replace)

      cat = Systemd::Journal.catalog_for(self[:message_id])
      # catalog_for does not do field substitution for us, so we do it here
      # if requested
      opts[:replace] ? field_substitute(cat) : cat
    end

    # Returns true if this Journal Entry has an associated catalog message.
    # @return [Boolean] whether or not this entry has an associated catalog
    #   message.
    def catalog?
      !self[:message_id].nil?
    end

    # Convert this Entry into a hash.
    # @return [Hash] the hash representation of this journal entry.
    def to_h
      @entry.each_with_object({}) { |(k, v), h| h[k] = v.dup }
    end

    # @private
    def inspect
      format('#<%s:0x%016x %s>', self.class.name, object_id, @inspect)
    end

    private

    # @private
    def field_substitute(msg)
      msg.gsub(/@[A-Z_0-9]+@/) { |field| self[field[1..-2]] || field }
    end
  end
end
