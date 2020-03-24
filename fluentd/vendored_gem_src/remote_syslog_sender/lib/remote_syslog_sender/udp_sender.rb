require 'socket'
require 'syslog_protocol'
require 'remote_syslog_sender/sender'

module RemoteSyslogSender
  class UdpSender < Sender
    def initialize(remote_hostname, remote_port, options = {})
      super
      @socket = UDPSocket.new
    end

    private

    def send_msg(payload)
      @socket.send(payload, 0, @remote_hostname, @remote_port)
    end
  end
end
