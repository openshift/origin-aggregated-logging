require 'systemd/id128'

module Systemd
  # See {Systemd::Id128.machine_id}.
  def self.machine_id
    Systemd::Id128.machine_id
  end

  # See {Systemd::Id128.boot_id}.
  def self.boot_id
    Systemd::Id128.boot_id
  end
end
