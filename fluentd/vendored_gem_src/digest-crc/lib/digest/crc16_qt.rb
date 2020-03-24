require 'digest/crc16_ccitt'

module Digest
  #
  # Implements the CRC16_CCITT algorithm used in QT algorithms.
  #
  # @author Matthew Bednarski
  #
  class CRC16QT < CRC16CCITT

    FINAL_XOR = 0xffff

    #
    # Updates the CRC16 checksum.
    #
    # @param [String] data
    #   The data to update the checksum with.
    #
    def update(data)
      data.each_byte do |b|
        b = revert_byte(b)
        @crc = ((@table[((@crc >> 8) ^ b) & 0xff] ^ (@crc << 8)) & 0xffff)
      end

      return self
    end

    #
    # Calculates the CRC checksum value.
    #
    # @return [Integer]
    #
    def checksum
      crc = super
      crc ^= FINAL_XOR
      crc = revert_bits(crc)
      return crc
    end

    protected

    def revert_bits(cc)
      ob = 0
      b  = (1 << 15)

      16.times do |t|
        ob |= (1 << t) if (cc & b) != 0
        b >>= 1
      end

      return ob
    end

    def revert_byte(cc)
      ob = 0
      b  = (1 << 7)

      8.times do |t|
        ob |= (1 << t) if (cc & b) != 0
        b >>= 1
      end

      return ob
    end

  end
end
