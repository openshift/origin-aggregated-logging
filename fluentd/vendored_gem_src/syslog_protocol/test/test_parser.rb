require File.expand_path('../helper', __FILE__)

describe "syslog packet parser" do

  it "parse some valid packets" do
    p = SyslogProtocol.parse("<34>Oct 11 22:14:15 mymachine su: 'su root' failed for lonvick on /dev/pts/8")
    p.facility.should.equal 4
    p.severity.should.equal 2
    p.pri.should.equal 34
    p.hostname.should.equal "mymachine"
    p.tag.should.equal 'su'
    p.content.should.equal "'su root' failed for lonvick on /dev/pts/8"
    p.time.should.equal Time.parse("Oct 11 22:14:15")

    p = SyslogProtocol.parse("<13>Feb  5 17:32:18 10.0.0.99 test: Use the BFG!")
    p.facility.should.equal 1
    p.severity.should.equal 5
    p.pri.should.equal 13
    p.hostname.should.equal "10.0.0.99"
    p.tag.should.equal 'test'
    p.content.should.equal "Use the BFG!"
    p.time.should.equal Time.parse("Feb  5 17:32:18")
  end

  it "treat a packet with no valid PRI as all content, setting defaults" do
    p = SyslogProtocol.parse("nomnom")
    p.facility.should.equal 1
    p.severity.should.equal 5
    p.pri.should.equal 13
    p.hostname.should.equal 'unknown'
    p.content.should.equal "nomnom"
  end

  it "PRI with preceding 0's shall be considered invalid" do
    p = SyslogProtocol.parse("<045>Oct 11 22:14:15 space_station my PRI is not valid")
    p.facility.should.equal 1
    p.severity.should.equal 5
    p.pri.should.equal 13
    p.hostname.should.equal 'unknown'
    p.content.should.equal "<045>Oct 11 22:14:15 space_station my PRI is not valid"
  end

  it "allow the user to pass an origin to be used as the hostname if packet is invalid" do
    p = SyslogProtocol.parse("<045>Oct 11 22:14:15 space_station my PRI is not valid", '127.0.0.1')
    p.facility.should.equal 1
    p.severity.should.equal 5
    p.pri.should.equal 13
    p.hostname.should.equal '127.0.0.1'
    p.content.should.equal "<045>Oct 11 22:14:15 space_station my PRI is not valid"
  end
end