require 'ostruct'
unless OpenStruct.instance_methods.include?(:dig)
  OpenStruct.class_eval do
    #
    # Retrieves the value object corresponding to the each +name+
    # objects repeatedly.
    #
    #   address = OpenStruct.new('city' => "Anytown NC", 'zip' => 12345)
    #   person = OpenStruct.new('name' => 'John Smith', 'address' => address)
    #   person.dig(:address, 'zip') # => 12345
    #   person.dig(:business_address, 'zip') # => nil
    #
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
