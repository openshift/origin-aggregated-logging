require 'spec_helper'

RSpec.describe Systemd do
  describe 'machine_id' do
    it 'is an alias for Systemd::Id128.machine_id' do
      expect(Systemd::Id128).to receive(:machine_id)
      Systemd.machine_id
    end
  end

  describe 'boot_id' do
    it 'is an alias for Systemd::Id128.boot_id' do
      expect(Systemd::Id128).to receive(:boot_id)
      Systemd.boot_id
    end
  end
end
