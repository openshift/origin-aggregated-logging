
require 'remote_syslog_sender/udp_sender'
require 'remote_syslog_sender/tcp_sender'

module RemoteSyslogSender
  VERSION = '1.0.3'

  def self.new(remote_hostname, remote_port, options = {})
    protocol = options.delete(:protocol)
    if protocol && protocol.to_sym == :tcp
      TcpSender.new(remote_hostname, remote_port, options)
    else
      UdpSender.new(remote_hostname, remote_port, options)
    end
  end
end
