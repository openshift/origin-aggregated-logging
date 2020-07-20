require 'dig_rb/version'
require 'dig_rb/hash'
require 'dig_rb/array'
require 'dig_rb/struct'
require 'dig_rb/ostruct'

module DigRb
  def self.guard_dig(obj)
    unless obj.respond_to?(:dig)
      raise TypeError, "#{obj.class.name} does not have #dig method"
    end
  end
end
