require 'spec_helper'

RSpec.describe Systemd::Id128 do
  subject(:id128) { Systemd::Id128 }

  describe 'machine_id' do
    it 'should be a 128 bit hexadecimal string' do
      expect(id128.machine_id).to match(/[0-9a-f]{16}/)
    end

    it 'should match when called twice' do
      m1 = id128.machine_id
      m2 = id128.machine_id
      expect(m1).to eq(m2)
    end
  end

  # travis-ci does not boot with systemd so these cases
  # will raise exceptions.
  context 'when booted under systemd' do
    describe 'boot_id' do
      it 'should be a 128 bit hexadecimal string' do
        expect(id128.boot_id).to match(/[0-9a-f]{16}/)
      end

      it 'should match when called twice' do
        b1 = id128.boot_id
        b2 = id128.boot_id
        expect(b1).to eq(b2)
      end
    end
  end unless ENV['TRAVIS']

  describe 'random' do
    it 'should be a 128 bit hexadecimal string' do
      expect(id128.random).to match(/[0-9a-f]{16}/)
    end

    it 'should return a different value when called again' do
      r1 = id128.random
      r2 = id128.random
      expect(r1).to_not eq(r2)
    end
  end
end
