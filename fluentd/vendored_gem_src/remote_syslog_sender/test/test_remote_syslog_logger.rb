require File.expand_path('../helper', __FILE__)

class TestRemoteSyslogSender < Test::Unit::TestCase
  def setup
    @server_port = rand(50000) + 1024
    @socket = UDPSocket.new
    @socket.bind('127.0.0.1', @server_port)

    @tcp_server = TCPServer.open('127.0.0.1', 0)
    @tcp_server_port = @tcp_server.addr[1]

    @tcp_server_wait_thread = Thread.start do
      @tcp_server.accept
    end
  end

  def teardown
    @socket.close
    @tcp_server.close
  end

  def test_sender
    @sender = RemoteSyslogSender.new('127.0.0.1', @server_port)
    @sender.write "This is a test"

    message, _ = *@socket.recvfrom(1024)
    assert_match(/This is a test/, message)
  end

  def test_sender_long_payload
    @sender = RemoteSyslogSender.new('127.0.0.1', @server_port, packet_size: 10240)
    @sender.write "abcdefgh" * 1000

    message, _ = *@socket.recvfrom(10240)
    assert_match(/#{"abcdefgh" * 1000}/, message)
  end

  def test_sender_tcp
    @sender = RemoteSyslogSender.new('127.0.0.1', @tcp_server_port, protocol: :tcp)
    @sender.write "This is a test"
    sock = @tcp_server_wait_thread.value

    message, _ = *sock.recvfrom(1024)
    assert_match(/This is a test/, message)
  end

  def test_sender_tcp_nonblock
    @sender = RemoteSyslogSender.new('127.0.0.1', @tcp_server_port, protocol: :tcp, timeout: 20)
    @sender.write "This is a test"
    sock = @tcp_server_wait_thread.value

    message, _ = *sock.recvfrom(1024)
    assert_match(/This is a test/, message)
  end

  def test_sender_multiline
    @sender = RemoteSyslogSender.new('127.0.0.1', @server_port)
    @sender.write "This is a test\nThis is the second line"

    message, _ = *@socket.recvfrom(1024)
    assert_match(/This is a test/, message)

    message, _ = *@socket.recvfrom(1024)
    assert_match(/This is the second line/, message)
  end
end
