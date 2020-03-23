require 'digest/crc16'

module Digest
  #
  # Implements the CRC16 USB algorithm.
  #
  class CRC16USB < CRC16

    INIT_CRC = 0xffff

    XOR_MASK = 0xffff

  end
end
