unless Struct.instance_methods.include?(:dig)
  Struct.class_eval do

    # Extracts the nested value specified by the sequence of <i>idx</i>
    # objects by calling +dig+ at each step, returning +nil+ if any
    # intermediate step is +nil+.

    #    klass = Struct.new(:a)
    #    o = klass.new(klass.new({b: [1, 2, 3]}))

    #    o.dig(:a, :a, :b, 0)              #=> 1
    #    o.dig(:b, 0)                      #=> nil
    def dig(name, *args)
      begin
        name = name.to_sym
      rescue NoMethodError
        raise TypeError, "#{name} is not a symbol nor a string"
      end
      return nil unless self.respond_to?(name)
      value = self.send(name)
      return value if args.length == 0 || value.nil?
      DigRb.guard_dig(value)
      value.dig(*args)
    end
  end
end
