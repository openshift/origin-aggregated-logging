unless Hash.instance_methods.include?(:dig)
  Hash.class_eval do
    # Retrieves the value object corresponding to the each key objects repeatedly.
    #
    #     h = { foo: {bar: {baz: 1}}}
    #     h.dig(:foo, :bar, :baz)           #=> 1
    #     h.dig(:foo, :zot)                 #=> nil
    def dig(key, *args)
      value = self[key]
      return value if args.length == 0 || value.nil?
      DigRb.guard_dig(value)
      value.dig(*args)
    end
  end
end
