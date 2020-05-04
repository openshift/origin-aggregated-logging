require 'spec_helper'
require 'crc_examples'
require 'digest/crc16_qt'

describe Digest::CRC16QT do
  let(:string)   { '1234567890' }
  let(:expected) { '4b13' }

  it_should_behave_like "CRC"
end
