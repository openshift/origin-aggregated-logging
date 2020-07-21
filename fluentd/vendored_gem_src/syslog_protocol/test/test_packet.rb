require File.expand_path('../helper', __FILE__)

describe "a syslog packet" do

  @p = SyslogProtocol::Packet.new

  it "should embarrass a person who does not set the fields" do
    lambda { @p.to_s }.should.raise RuntimeError
  end

  it "hostname may not be omitted" do
    lambda {@p.hostname = ""}.should.raise ArgumentError
  end

  it "hostname may only contain ASCII characters 33-126 (no spaces!)" do
    lambda {@p.hostname = "linux box"}.should.raise ArgumentError
    lambda {@p.hostname = "\000" + "linuxbox"}.should.raise ArgumentError
    lambda {@p.hostname = "space_station"}.should.not.raise
  end

  it 'tag may only contain ASCII characters 33-126 (no spaces!)' do
    lambda {@p.tag = "linux box"}.should.raise ArgumentError
    lambda {@p.tag = "\000" + "linuxbox"}.should.raise ArgumentError
    lambda {@p.tag = "test"}.should.not.raise
  end

  it "facility may only be set within 0-23 or with a proper string name" do
    lambda {@p.facility = 666}.should.raise ArgumentError
    lambda {@p.facility = "mir space station"}.should.raise ArgumentError

    lambda {@p.facility = 16}.should.not.raise
    @p.facility.should.equal 16
    lambda {@p.facility = 'local0'}.should.not.raise
    @p.facility.should.equal 16
  end

  it "severity may only be set within 0-7 or with a proper string name" do
    lambda {@p.severity = 9876}.should.raise ArgumentError
    lambda {@p.severity = "omgbroken"}.should.raise ArgumentError

    lambda {@p.severity = 6}.should.not.raise
    @p.severity.should.equal 6
    lambda {@p.severity = 'info'}.should.not.raise
    @p.severity.should.equal 6
  end

  it "severity can be checked using 'some_severity?' methods" do
    @p.info?.should.equal true
    @p.alert?.should.equal false
    @p.emerg?.should.equal false
  end

  it "PRI is calculated from the facility and severity" do
    @p.pri.should.equal 134
  end

  it "PRI may only be within 0-191" do
    lambda {@p.pri = 22331}.should.raise ArgumentError
    lambda {@p.pri = "foo"}.should.raise ArgumentError
  end

  it "facility and severity are deduced and set from setting a valid PRI" do
    @p.pri = 165
    @p.severity.should.equal 5
    @p.facility.should.equal 20
  end

  it "return the proper names for facility and severity" do
    @p.severity_name.should.equal 'notice'
    @p.facility_name.should.equal 'local4'
  end

  it "set a message, which apparently can be anything" do
    @p.content = "exploring ze black hole"
    @p.content.should.equal "exploring ze black hole"
  end

  it "timestamp must conform to the retarded format" do
    @p.generate_timestamp.should.match /(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s(\s|[1-9])\d\s\d\d:\d\d:\d\d/
  end

  it "use the current time and assemble the packet" do
    timestamp = @p.generate_timestamp
    @p.to_s.should.equal "<165>#{timestamp} space_station test: exploring ze black hole"
  end

  it "packets larger than 1024 will be truncated" do
    @p.content = "space warp" * 1000
    if "".respond_to?(:bytesize)
      @p.to_s.bytesize.should.equal 1024
    else
      @p.to_s.size.should.equal 1024
    end
  end

end